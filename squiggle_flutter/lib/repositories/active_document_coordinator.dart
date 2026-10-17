import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';

/// Keeps the in-memory [EditorContext] document and the persisted document
/// it was loaded from in step: loads on open, autosaves on change, and
/// flushes before switching away.
class ActiveDocumentCoordinator extends ChangeNotifier {
  ActiveDocumentCoordinator({
    required this.documentStorage,
    required this.documentList,
    required this.context,
  });

  final DocumentStorage documentStorage;
  final DocumentListNotifier documentList;
  final EditorContext context;

  String? _activeId;
  String _activeName = '';
  bool _autosaveSubscribed = false;

  String? get activeId => _activeId;

  Future<void> initialize() async {
    await documentStorage.initialize();
    await documentList.refresh();

    final storedId = await documentStorage.loadActiveDocumentId();
    final documents = documentList.documents;
    final DocumentInfo info;
    if (documents.any((document) => document.id == storedId)) {
      info = documents.firstWhere((document) => document.id == storedId);
    } else if (documents.isNotEmpty) {
      info = documents.first;
    } else {
      info = await documentStorage.createDocument();
      await documentList.refresh();
    }
    await _activate(info);

    context.history.addListener(_autosave);
    context.brushes.addListener(_autosave);
    _autosaveSubscribed = true;
  }

  Future<DocumentInfo> createDocument({String? name}) async {
    await flush();
    final created = await documentStorage.createDocument(name: name);
    await documentList.refresh();
    await _activate(created);
    return created;
  }

  Future<void> openDocument(String id) async {
    if (_activeId == id) return;
    await flush();
    await _activate(_infoFor(id));
  }

  /// Writes the active document and waits for the write to finish.
  Future<void> flush() async {
    final id = _activeId;
    if (id == null) return;
    await documentStorage.saveDocument(id, context.document, _activeName);
  }

  Future<void> renameDocument(String id, String newName) async {
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return;

    await documentStorage.renameDocument(id, trimmed);
    if (_activeId == id) _activeName = trimmed;
    await documentList.refresh();
  }

  Future<void> deleteDocument(String id) async {
    if (documentList.documents.length <= 1) return;

    await documentStorage.deleteDocument(id);
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
    _activeName = info.name;
    final stored = await documentStorage.loadDocument(info.id);
    context.loadDocument(stored?.document ?? Document());
    await documentStorage.saveActiveDocumentId(info.id);
    notifyListeners();
  }

  void _autosave() {
    final id = _activeId;
    if (id == null) return;

    unawaited(documentStorage.saveDocument(id, context.document, _activeName));
  }
}
