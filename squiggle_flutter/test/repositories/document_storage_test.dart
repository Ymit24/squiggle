import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentStorage', () {
    late Directory tempDir;
    late ImageRepository imageRepository;
    late DocumentStorage storage;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('squiggle_docs_');
      imageRepository = ImageRepository(
        imagesDirectory: Directory('${tempDir.path}/images'),
      );
      await imageRepository.initialize();
      storage = DocumentStorage(
        imageRepository: imageRepository,
        storageDirectory: tempDir,
      );
      await storage.initialize();
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('creates, lists, loads, renames, and deletes documents', () async {
      final created = await storage.createDocument(name: 'First');
      expect(created.name, 'First');

      final documents = await storage.listDocuments();
      expect(documents, hasLength(1));
      expect(documents.first.id, created.id);

      final loaded = await storage.loadDocument(created.id);
      expect(loaded, isNotNull);
      expect(loaded!.document.features, isEmpty);
      expect(loaded.name, 'First');

      await storage.renameDocument(created.id, 'Renamed');
      final renamed = await storage.readDocumentInfo(created.id);
      expect(renamed?.name, 'Renamed');

      final second = await storage.createDocument(name: 'Second');
      expect(await storage.listDocuments(), hasLength(2));

      await storage.deleteDocument(second.id);
      expect(await storage.listDocuments(), hasLength(1));
      expect(await storage.loadDocument(second.id), isNull);
    });

    test('migrates legacy document.json into documents directory', () async {
      final legacyDir = await Directory.systemTemp.createTemp('squiggle_legacy_');
      addTearDown(() => legacyDir.delete(recursive: true));

      final legacyImageRepository = ImageRepository(
        imagesDirectory: Directory('${legacyDir.path}/images'),
      );
      await legacyImageRepository.initialize();

      final legacy = File('${legacyDir.path}/document.json');
      await legacy.writeAsString(
        '{"version":1,"name":"Legacy","nextId":1,"features":[]}',
      );

      final migratedStorage = DocumentStorage(
        imageRepository: legacyImageRepository,
        storageDirectory: legacyDir,
      );
      await migratedStorage.initialize();

      final documents = await migratedStorage.listDocuments();
      expect(documents, hasLength(1));
      expect(documents.first.name, 'Legacy');
      expect(await legacy.exists(), isFalse);
    });

    test('persists and restores active document id', () async {
      final created = await storage.createDocument(name: 'Active');
      await storage.saveActiveDocumentId(created.id);
      expect(await storage.loadActiveDocumentId(), created.id);
    });
  });
}
