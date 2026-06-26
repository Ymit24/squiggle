import 'dart:async';

import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/selection.dart';

/// Manages the set of persisted documents and the active in-memory document.
class DocumentLibraryRepository {
  DocumentLibraryRepository({
    required this.documentStorage,
    required this.documentRepository,
    required this.selectionRepository,
  });

  final DocumentStorage documentStorage;
  final DocumentRepository documentRepository;
  final SelectionRepository selectionRepository;

  final StreamController<void> _changesController =
      StreamController<void>.broadcast();
  StreamSubscription<void>? _autosaveSubscription;

  List<DocumentInfo> _documents = [];
  DocumentInfo? _currentDocument;

  List<DocumentInfo> get documents => List.unmodifiable(_documents);
  DocumentInfo? get currentDocument => _currentDocument;
  Stream<void> get changesStream => _changesController.stream;

  Future<void> initialize() async {
    await documentStorage.initialize();
    _documents = await documentStorage.listDocuments();

    final activeId = await documentStorage.loadActiveDocumentId();
    if (activeId != null && _documents.any((document) => document.id == activeId)) {
      await _openDocument(activeId, saveCurrent: false);
    } else if (_documents.isNotEmpty) {
      await _openDocument(_documents.first.id, saveCurrent: false);
    } else {
      final created = await documentStorage.createDocument();
      _documents = await documentStorage.listDocuments();
      _currentDocument = created;
      documentRepository.replaceDocument(Document());
      await documentStorage.saveActiveDocumentId(created.id);
    }

    _attachAutosave();
    _notify();
  }

  Future<void> createDocument({String? name}) async {
    await _saveCurrentDocument();
    final created = await documentStorage.createDocument(name: name);
    _documents = await documentStorage.listDocuments();
    await _loadDocumentIntoRepository(created.id);
    _currentDocument = _documents.firstWhere(
      (document) => document.id == created.id,
    );
    await documentStorage.saveActiveDocumentId(created.id);
    selectionRepository.clearSelection();
    _notify();
  }

  Future<void> openDocument(String id) async {
    if (_currentDocument?.id == id) {
      return;
    }
    await _openDocument(id, saveCurrent: true);
  }

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

  Future<void> saveCurrentDocument() => _saveCurrentDocument();

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

  Future<void> _openDocument(String id, {required bool saveCurrent}) async {
    if (saveCurrent) {
      await _saveCurrentDocument();
    }

    await _loadDocumentIntoRepository(id);
    _currentDocument = _documents.firstWhere((document) => document.id == id);
    await documentStorage.saveActiveDocumentId(id);
    selectionRepository.clearSelection();
    _notify();
  }

  Future<void> _loadDocumentIntoRepository(String id) async {
    final decoded = await documentStorage.loadDocument(id);
    documentRepository.replaceDocument(decoded?.document ?? Document());
  }

  Future<void> _saveCurrentDocument() async {
    final current = _currentDocument;
    if (current == null) {
      return;
    }

    await documentStorage.saveDocument(
      current.id,
      documentRepository.document,
      current.name,
    );
    _documents = await documentStorage.listDocuments();
    _currentDocument = _documents.firstWhere(
      (document) => document.id == current.id,
      orElse: () => current,
    );
  }

  void _attachAutosave() {
    _autosaveSubscription?.cancel();
    _autosaveSubscription = documentRepository.changesStream.listen((_) {
      final current = _currentDocument;
      if (current == null) {
        return;
      }

      unawaited(
        documentStorage.saveDocument(
          current.id,
          documentRepository.document,
          current.name,
        ),
      );
      unawaited(_refreshDocumentInfo(current.id));
    });
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

  void dispose() {
    _autosaveSubscription?.cancel();
    _autosaveSubscription = null;
    _changesController.close();
  }
}
