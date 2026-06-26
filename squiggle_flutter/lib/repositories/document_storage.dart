import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:path_provider/path_provider.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/document_codec.dart';

/// Persists documents as individual JSON files in the app data directory.
class DocumentStorage {
  DocumentStorage({
    required this.imageRepository,
    Directory? storageDirectory,
  }) : _storageDirectory = storageDirectory;

  final ImageRepository imageRepository;
  Directory? _storageDirectory;
  Future<void>? _initializeFuture;
  bool _initialized = false;

  static const _legacyDocumentFileName = 'document.json';
  static const _documentsDirName = 'documents';
  static const _activeDocumentFileName = 'active_document.txt';
  static const _defaultDocumentName = 'Untitled';

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    _initializeFuture ??= _initializeOnce();
    await _initializeFuture;
  }

  Future<void> _initializeOnce() async {
    await _ensureStorageReady();
    await _migrateLegacyDocumentIfNeeded();
    _initialized = true;
  }

  Future<void> _ensureStorageReady() async {
    _storageDirectory ??= await _defaultStorageDirectory();
    await _storageDirectory!.create(recursive: true);
    await _documentsDirectory.create(recursive: true);
  }

  Future<Directory> _defaultStorageDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    return Directory('${supportDir.path}/Squiggle');
  }

  Directory get _documentsDirectory {
    final directory = _storageDirectory;
    if (directory == null) {
      throw StateError('DocumentStorage.initialize() must be called first.');
    }
    return Directory('${directory.path}/$_documentsDirName');
  }

  File _documentFile(String id) => File('${_documentsDirectory.path}/$id.json');

  File get _activeDocumentFile {
    final directory = _storageDirectory;
    if (directory == null) {
      throw StateError('DocumentStorage.initialize() must be called first.');
    }
    return File('${directory.path}/$_activeDocumentFileName');
  }

  Future<void> _migrateLegacyDocumentIfNeeded() async {
    final storage = _storageDirectory;
    if (storage == null) {
      return;
    }

    final legacyFile = File('${storage.path}/$_legacyDocumentFileName');
    if (!await legacyFile.exists()) {
      return;
    }

    final hasDocuments = _documentsDirectory
        .listSync()
        .any((entity) => entity.path.endsWith('.json'));
    if (hasDocuments) {
      return;
    }

    try {
      final json = await legacyFile.readAsString();
      final decoded = decodeDocumentWithName(json);
      if (decoded == null) {
        return;
      }

      final id = _generateDocumentId();
      await saveDocument(id, decoded.document, decoded.name);
      await saveActiveDocumentId(id);
      await legacyFile.delete();
    } on Object {
      // Leave legacy file in place if migration fails.
    }
  }

  Future<List<DocumentInfo>> listDocuments() async {
    await initialize();

    final documents = <DocumentInfo>[];
    for (final entity in _documentsDirectory.listSync()) {
      if (entity is! File || !entity.path.endsWith('.json')) {
        continue;
      }

      final info = await _readDocumentInfo(entity);
      if (info != null) {
        documents.add(info);
      }
    }

    documents.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return documents;
  }

  Future<DocumentInfo?> readDocumentInfo(String id) async {
    await initialize();
    return _readDocumentInfo(_documentFile(id));
  }

  Future<DecodedDocument?> loadDocument(String id) async {
    await initialize();
    final file = _documentFile(id);
    if (!await file.exists()) {
      return null;
    }

    try {
      final json = await file.readAsString();
      return decodeDocumentWithName(json);
    } on Object {
      return null;
    }
  }

  Future<DocumentInfo> createDocument({String? name}) async {
    await initialize();
    final id = _generateDocumentId();
    final documentName = name ?? await _nextUntitledName();
    final info = DocumentInfo(
      id: id,
      name: documentName,
      updatedAt: DateTime.now(),
      featureCount: 0,
    );
    await saveDocument(id, Document(), documentName);
    return info;
  }

  Future<void> saveDocument(
    String id,
    Document document,
    String name,
  ) async {
    await _ensureStorageReady();
    try {
      final json = await encodeDocument(
        document,
        imageRepository,
        name: name,
      );
      await _documentFile(id).writeAsString(json, flush: true);
    } on Object {
      // Ignore persistence failures during autosave.
    }
  }

  Future<void> renameDocument(String id, String newName) async {
    await initialize();
    final file = _documentFile(id);
    if (!await file.exists()) {
      return;
    }

    try {
      final json = await file.readAsString();
      final decoded = decodeDocumentWithName(json);
      if (decoded == null) {
        return;
      }

      await saveDocument(id, decoded.document, newName);
    } on Object {
      // Ignore rename failures.
    }
  }

  Future<void> deleteDocument(String id) async {
    await initialize();
    final file = _documentFile(id);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String?> loadActiveDocumentId() async {
    await initialize();
    final file = _activeDocumentFile;
    if (!await file.exists()) {
      return null;
    }

    try {
      final id = (await file.readAsString()).trim();
      return id.isEmpty ? null : id;
    } on Object {
      return null;
    }
  }

  Future<void> saveActiveDocumentId(String id) async {
    await _ensureStorageReady();
    try {
      await _activeDocumentFile.writeAsString(id, flush: true);
    } on Object {
      // Ignore persistence failures.
    }
  }

  Future<DocumentInfo?> _readDocumentInfo(File file) async {
    try {
      final stat = await file.stat();
      final json = await file.readAsString();
      final decoded = decodeDocumentWithName(json);
      if (decoded == null) {
        return null;
      }

      final id = file.uri.pathSegments.last.replaceAll('.json', '');
      return DocumentInfo(
        id: id,
        name: decoded.name,
        updatedAt: stat.modified,
        featureCount: decoded.document.features.length,
      );
    } on Object {
      return null;
    }
  }

  Future<String> _nextUntitledName() async {
    final documents = await listDocuments();
    final usedNames = documents.map((document) => document.name).toSet();
    if (!usedNames.contains(_defaultDocumentName)) {
      return _defaultDocumentName;
    }

    var index = 2;
    while (usedNames.contains('$_defaultDocumentName $index')) {
      index++;
    }
    return '$_defaultDocumentName $index';
  }

  String _generateDocumentId() {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final random = math.Random().nextInt(0xFFFFFF);
    return 'doc_${timestamp}_${random.toRadixString(16).padLeft(6, '0')}';
  }
}
