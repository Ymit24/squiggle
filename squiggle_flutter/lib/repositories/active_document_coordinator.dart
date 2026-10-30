import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/database/daos/app_state_dao.dart';
import 'package:squiggle_flutter/database/daos/documents_dao.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';

/// The document asked for does not exist in the database.
class DocumentNotFoundException implements Exception {
  const DocumentNotFoundException(this.id);

  final String id;

  @override
  String toString() => 'DocumentNotFoundException: no document with id $id';
}

/// Writing the active document failed; its latest edits are only in memory.
class DocumentSaveException implements Exception {
  const DocumentSaveException(this.id, this.cause);

  final String id;
  final Object cause;

  @override
  String toString() => 'DocumentSaveException: could not save $id: $cause';
}

/// Keeps the in-memory [EditorContext] document and the persisted document
/// it was loaded from in step: loads on open, autosaves on change, and
/// flushes before switching away.
///
/// [activeId] and the document in [context] always change together, in one
/// synchronous step after the new document has loaded, so a write never pairs
/// one document's id with another document's content.
///
/// A document whose stored body cannot be read is never written back: the
/// stored row is left as it was and [loadError] is set until another document
/// is opened or the same one loads successfully.
class ActiveDocumentCoordinator extends ChangeNotifier {
  ActiveDocumentCoordinator({
    required this.documentsDao,
    required this.appStateDao,
    required this.documentList,
    required this.context,
  });

  final DocumentsDao documentsDao;
  final AppStateDao appStateDao;
  final DocumentListNotifier documentList;
  final EditorContext context;

  String? _activeId;
  Object? _loadError;
  DocumentSaveException? _saveError;

  /// Bumped whenever an activation starts or the active document is dropped,
  /// so an older activation that finishes loading late does not swap in.
  int _generation = 0;

  /// True while [EditorContext.loadDocument] runs; its notifications are not
  /// edits and must not autosave (or bump `updatedAt`).
  bool _swapping = false;
  bool _disposed = false;
  bool _autosaveSubscribed = false;
  bool _saveRequested = false;
  Future<void>? _saving;

  String? get activeId => _activeId;

  /// Why the active document could not be read, or null if it loaded.
  Object? get loadError => _loadError;

  Future<void> initialize() async {
    await documentList.refresh();

    final storedId = await appStateDao.activeDocumentId();
    final documents = documentList.documents;
    final String id;
    if (documents.any((document) => document.id == storedId)) {
      id = storedId!;
    } else if (documents.isNotEmpty) {
      id = documents.first.id;
    } else {
      final created = await documentsDao.create(
        name: documentList.nextUntitledName(),
      );
      await documentList.refresh();
      id = created.id;
    }
    await _activate(id);

    context.history.addListener(_autosave);
    context.brushes.addListener(_autosave);
    _autosaveSubscribed = true;
  }

  Future<DocumentInfo> createDocument({String? name}) async {
    await flush();
    final created = await documentsDao.create(
      name: name ?? documentList.nextUntitledName(),
    );
    await documentList.refresh();
    await _activate(created.id);
    return created;
  }

  /// Opens [id], or retries it if it is active but failed to load.
  Future<void> openDocument(String id) async {
    if (_activeId == id && _loadError == null) return;
    await flush();
    await _activate(id);
  }

  /// Waits for every pending write of the active document, retrying the last
  /// one if it failed. A document without unsaved edits is not rewritten.
  ///
  /// Throws [DocumentSaveException] if the write failed, so callers do not
  /// replace or leave a document whose edits are only in memory.
  Future<void> flush() async {
    if (_activeId == null || _loadError != null) return;
    if (_saveError != null) unawaited(_requestSave());
    await _settleSaves();
    final error = _saveError;
    if (error != null) throw error;
  }

  /// Stops tracking the active document without saving it, after a failed
  /// save the user chose to abandon. The next open or create proceeds.
  void discardActiveDocument() {
    _generation++;
    _activeId = null;
    _loadError = null;
    _saveError = null;
    _saveRequested = false;
  }

  Future<void> renameDocument(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    await documentsDao.rename(id, trimmed);
    await documentList.refresh();
  }

  Future<void> deleteDocument(String id) async {
    if (documentList.documents.length <= 1) return;

    await documentsDao.remove(id);
    await documentList.refresh();

    if (_activeId == id) {
      await _activate(documentList.documents.first.id);
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _saveRequested = false;
    if (_autosaveSubscribed) {
      context.history.removeListener(_autosave);
      context.brushes.removeListener(_autosave);
      _autosaveSubscribed = false;
    }
    super.dispose();
  }

  Future<void> _activate(String id) async {
    final generation = ++_generation;
    Document document;
    Object? loadError;
    try {
      final stored = await documentsDao.load(id);
      if (stored == null) throw DocumentNotFoundException(id);
      document = Document.fromDataModel(stored);
    } on Object catch (error, stackTrace) {
      loadError = error;
      document = Document();
      _report(error, stackTrace, 'while loading document $id');
    }

    // Edits that reached the outgoing document while this one loaded belong
    // to it; write them under its id before swapping.
    await _settleSaves();
    if (generation != _generation || _disposed) return;

    _activeId = id;
    _loadError = loadError;
    _saveError = null;
    _swapping = true;
    try {
      context.loadDocument(document);
    } finally {
      _swapping = false;
    }
    notifyListeners();
    await appStateDao.setActiveDocumentId(id);
  }

  Future<void> _settleSaves() async {
    while (_saving != null) {
      await _saving;
    }
  }

  void _autosave() {
    if (_swapping || _activeId == null || _loadError != null) return;
    unawaited(_requestSave());
  }

  Future<void> _requestSave() {
    _saveRequested = true;
    return _saving ??= _drainSaves();
  }

  /// Writes the active document until no change arrived during the last
  /// write. The document is read when each write starts, so a burst of edits
  /// costs one write in flight plus at most one more, never a queue.
  ///
  /// [_activate] waits for this loop to finish before swapping documents, so
  /// the id and content read here always belong together.
  Future<void> _drainSaves() async {
    // Yield first so the caller stores this future in `_saving` before the
    // loop can finish and clear it, and so edits in one turn share a write.
    await Future<void>.value();
    try {
      while (_saveRequested && !_disposed) {
        _saveRequested = false;
        final id = _activeId;
        if (id == null || _loadError != null) return;
        final body = context.document.toDataModel();
        try {
          await documentsDao.save(id, body);
          if (_activeId == id) _saveError = null;
        } on Object catch (error, stackTrace) {
          if (_activeId == id) _saveError = DocumentSaveException(id, error);
          _report(error, stackTrace, 'while saving document $id');
        }
      }
    } finally {
      _saving = null;
    }
  }

  void _report(Object error, StackTrace stackTrace, String description) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'ActiveDocumentCoordinator',
        context: ErrorDescription(description),
      ),
    );
  }
}
