import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/database/daos/app_state_dao.dart';
import 'package:squiggle_flutter/database/daos/documents_dao.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';

/// Keeps the in-memory [EditorContext] document and the persisted document
/// it was loaded from in step: loads on open, autosaves on change, and
/// flushes before switching away.
///
/// A document whose stored body cannot be read is never written back: the
/// stored row is left as it was and [loadError] is set until another document
/// is opened.
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
    final DocumentInfo info;
    if (documents.any((document) => document.id == storedId)) {
      info = documents.firstWhere((document) => document.id == storedId);
    } else if (documents.isNotEmpty) {
      info = documents.first;
    } else {
      info = await documentsDao.create(name: documentList.nextUntitledName());
      await documentList.refresh();
    }
    await _activate(info);

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
    await _activate(created);
    return created;
  }

  Future<void> openDocument(String id) async {
    if (_activeId == id) return;
    await flush();
    await _activate(_infoFor(id));
  }

  /// Writes the active document and waits for every pending write.
  Future<void> flush() async {
    if (_activeId == null || _loadError != null) return;
    await _requestSave();
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
      await _activate(documentList.documents.first);
    }
  }

  @override
  void dispose() {
    if (_autosaveSubscribed) {
      context.history.removeListener(_autosave);
      context.brushes.removeListener(_autosave);
      _autosaveSubscribed = false;
    }
    super.dispose();
  }

  DocumentInfo _infoFor(String id) =>
      documentList.documents.firstWhere((document) => document.id == id);

  Future<void> _activate(DocumentInfo info) async {
    _activeId = info.id;
    _loadError = null;
    Document document;
    try {
      final stored = await documentsDao.load(info.id);
      document = stored == null ? Document() : Document.fromDataModel(stored);
    } on Object catch (error, stackTrace) {
      _loadError = error;
      document = Document();
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'ActiveDocumentCoordinator',
          context: ErrorDescription('while loading document ${info.id}'),
        ),
      );
    }
    context.loadDocument(document);
    await appStateDao.setActiveDocumentId(info.id);
    notifyListeners();
  }

  void _autosave() {
    if (_activeId == null || _loadError != null) return;
    unawaited(_requestSave());
  }

  Future<void> _requestSave() {
    _saveRequested = true;
    return _saving ??= _drainSaves();
  }

  /// Writes the active document until no change arrived during the last
  /// write. The document is read when each write starts, so a burst of edits
  /// costs one write in flight plus at most one more, never a queue.
  Future<void> _drainSaves() async {
    // Yield first so the caller stores this future in `_saving` before the
    // loop can finish and clear it, and so edits in one turn share a write.
    await Future<void>.value();
    try {
      while (_saveRequested) {
        _saveRequested = false;
        final id = _activeId;
        if (id == null || _loadError != null) return;
        try {
          await documentsDao.save(id, context.document.toDataModel());
        } on Object catch (error, stackTrace) {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stackTrace,
              library: 'ActiveDocumentCoordinator',
              context: ErrorDescription('while saving document $id'),
            ),
          );
        }
      }
    } finally {
      _saving = null;
    }
  }
}
