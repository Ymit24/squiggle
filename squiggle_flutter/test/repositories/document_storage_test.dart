import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

import 'package:flutter_test/flutter_test.dart';
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
      expect(loaded!.document.nodes, isEmpty);
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

    test(
      'brush snapshots are ordered and survive save, rename and reload',
      () async {
        final created = await storage.createDocument(name: 'Brushes');
        final editor = EditorContext(document: Document());
        addTearDown(editor.dispose);
        final brush = editor.createBrush('Construction');
        editor.setDrawingField('strokeColor', const Color(0xFFFFAA00));
        editor.setDrawingField('strokeType', StrokeType.dashed);
        final first = storage.saveDocument(
          created.id,
          editor.document,
          'Brushes',
        );
        editor.setDrawingField('strokeWidth', 3.0);
        final second = storage.saveDocument(
          created.id,
          editor.document,
          'Brushes',
        );
        await Future.wait([first, second]);
        await storage.renameDocument(created.id, 'Renamed');
        final restored = (await storage.loadDocument(created.id))!.document;
        expect(restored.name, 'Renamed');
        expect(restored.session.activeBrushId, brush.id);
        expect(restored.session.activeBrush.values, brush.values);
        expect(restored.session.scratch.values, isEmpty);
      },
    );

    test('persists and restores active document id', () async {
      final created = await storage.createDocument(name: 'Active');
      await storage.saveActiveDocumentId(created.id);
      expect(await storage.loadActiveDocumentId(), created.id);
    });

    test('writes version 2 and rejects older document versions', () async {
      final created = await storage.createDocument(name: 'Current');
      final currentFile = File('${tempDir.path}/documents/${created.id}.json');
      final currentJson = jsonDecode(await currentFile.readAsString()) as Map;
      expect(currentJson['version'], 2);

      await File(
        '${tempDir.path}/documents/old.json',
      ).writeAsString('{"version":1,"name":"Old","nodes":[]}');
      expect(await storage.loadDocument('old'), isNull);
      expect(
        (await storage.listDocuments()).map((document) => document.id),
        isNot(contains('old')),
      );
    });
  });
}
