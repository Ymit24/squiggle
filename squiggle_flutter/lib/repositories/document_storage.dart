import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/document_codec.dart';

/// Persists the editable document to the app data directory.
class DocumentStorage {
  DocumentStorage({
    required this.imageRepository,
    Directory? storageDirectory,
  }) : _storageDirectory = storageDirectory;

  final ImageRepository imageRepository;
  Directory? _storageDirectory;
  StreamSubscription<void>? _autosaveSubscription;

  static const _documentFileName = 'document.json';

  Future<void> initialize() async {
    _storageDirectory ??= await _defaultStorageDirectory();
    await _storageDirectory!.create(recursive: true);
  }

  Future<Directory> _defaultStorageDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    return Directory('${supportDir.path}/Squiggle');
  }

  File get _documentFile {
    final directory = _storageDirectory;
    if (directory == null) {
      throw StateError('DocumentStorage.initialize() must be called first.');
    }
    return File('${directory.path}/$_documentFileName');
  }

  Future<Document?> load() async {
    await initialize();
    final file = _documentFile;
    if (!await file.exists()) {
      return null;
    }

    try {
      final json = await file.readAsString();
      return decodeDocument(json);
    } on Object {
      return null;
    }
  }

  Future<void> save(Document document) async {
    await initialize();
    try {
      final json = await encodeDocument(document, imageRepository);
      await _documentFile.writeAsString(json, flush: true);
    } on Object {
      // Ignore persistence failures during autosave.
    }
  }

  void attachAutosave(DocumentRepository repository) {
    _autosaveSubscription?.cancel();
    _autosaveSubscription = repository.changesStream.listen((_) {
      unawaited(save(repository.document));
    });
  }

  void dispose() {
    _autosaveSubscription?.cancel();
  }
}
