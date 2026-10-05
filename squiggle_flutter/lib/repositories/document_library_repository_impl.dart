import 'dart:async';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';

/// Storage-backed implementation of [DocumentLibraryRepository].
class DocumentLibraryRepositoryImpl implements DocumentLibraryRepository {
  DocumentLibraryRepositoryImpl({
    required this.documentStorage,
    required this.context,
  });

  final DocumentStorage documentStorage;
  final EditorContext context;

  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  List<DocumentInfo> _documents = [];
  DocumentInfo? _currentDocument;

  bool _autosaveSubscribed = false;

  @override
  List<DocumentInfo> get documents => List.unmodifiable(_documents);

  @override
  DocumentInfo? get currentDocument => _currentDocument;

  @override
  Stream<void> get changesStream => _changesController.stream;

  @override
  Future<void> initialize() async {
    await documentStorage.initialize();
    _documents = await documentStorage.listDocuments();

    final activeId = await documentStorage.loadActiveDocumentId();
    if (activeId != null &&
        _documents.any((document) => document.id == activeId)) {
      await _openDocument(activeId, saveCurrent: false);
    } else if (_documents.isNotEmpty) {
      await _openDocument(_documents.first.id, saveCurrent: false);
    } else {
      final created = await documentStorage.createDocument();
      _documents = await documentStorage.listDocuments();
      _currentDocument = created;
      context.loadDocument(Document());
      await documentStorage.saveActiveDocumentId(created.id);
    }

    _attachAutosave();
    _notify();
  }

  @override
  Future<void> createDocument({String? name}) async {
    await _saveCurrentDocument();
    final created = await documentStorage.createDocument(name: name);
    _documents = await documentStorage.listDocuments();
    final info = _documents.firstWhere((document) => document.id == created.id);
    _currentDocument = info;
    await _loadDocumentIntoContext(created.id);
    await documentStorage.saveActiveDocumentId(created.id);
    _notify();
  }

  @override
  Future<void> openDocument(String id) async {
    if (_currentDocument?.id == id) {
      return;
    }
    await _openDocument(id, saveCurrent: true);
  }

  @override
  Future<void> refreshDocuments() async {
    _documents = await documentStorage.listDocuments();
    if (_currentDocument != null) {
      _currentDocument = _documents.firstWhere(
        (document) => document.id == _currentDocument!.id,
        orElse: () => _currentDocument!,
      );
    }
    _notify();
  }

  @override
  Future<void> saveCurrentDocument() => _saveCurrentDocument();

  @override
  Future<void> renameDocument(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return;
    }

    await documentStorage.renameDocument(id, trimmed);
    _documents = await documentStorage.listDocuments();
    if (_currentDocument?.id == id) {
      _currentDocument = _currentDocument!.copyWith(name: trimmed);
    }
    _notify();
  }

  @override
  Future<void> deleteDocument(String id) async {
    if (_documents.length <= 1) {
      return;
    }

    final deletingCurrent = _currentDocument?.id == id;
    await documentStorage.deleteDocument(id);
    _documents = await documentStorage.listDocuments();

    if (deletingCurrent) {
      await _openDocument(_documents.first.id, saveCurrent: false);
    }

    _notify();
  }

  @override
  void dispose() {
    if (_autosaveSubscribed) {
      context.history.removeListener(_autosave);
      context.brushes.removeListener(_autosave);
      _autosaveSubscribed = false;
    }
    _changesController.close();
  }

  Future<void> _openDocument(String id, {required bool saveCurrent}) async {
    if (saveCurrent) {
      await _saveCurrentDocument();
    }

    final info = _documents.firstWhere((document) => document.id == id);
    _currentDocument = info;
    await _loadDocumentIntoContext(id);
    await documentStorage.saveActiveDocumentId(id);
    _notify();
  }

  Future<void> _loadDocumentIntoContext(String id) async {
    final decoded = await documentStorage.loadDocument(id);
    context.loadDocument(decoded?.document ?? Document());
  }

  Future<void> _saveCurrentDocument() async {
    final current = _currentDocument;
    if (current == null) {
      return;
    }

    await documentStorage.saveDocument(
      current.id,
      context.document,
      current.name,
    );
    _documents = await documentStorage.listDocuments();
    _currentDocument = _documents.firstWhere(
      (document) => document.id == current.id,
      orElse: () => current,
    );
  }

  void _attachAutosave() {
    _autosaveSubscribed = true;
    context.history.addListener(_autosave);
    context.brushes.addListener(_autosave);
  }

  void _autosave() {
    final current = _currentDocument;
    if (current == null) {
      return;
    }

    unawaited(
      documentStorage.saveDocument(current.id, context.document, current.name),
    );
    unawaited(_refreshDocumentInfo(current.id));
  }

  Future<void> _refreshDocumentInfo(String id) async {
    final info = await documentStorage.readDocumentInfo(id);
    if (info == null) {
      return;
    }

    final index = _documents.indexWhere((document) => document.id == id);
    if (index == -1) {
      return;
    }

    _documents[index] = info;
    if (_currentDocument?.id == id) {
      _currentDocument = info;
    }
    _notify();
  }

  void _notify() {
    if (!_changesController.isClosed) {
      _changesController.add(null);
    }
  }
}
