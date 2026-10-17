import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/repositories/image_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentListNotifier', () {
    late Directory tempDir;
    late DocumentStorage storage;
    late DocumentListNotifier list;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('squiggle_list_');
      storage = DocumentStorage(
        imageRepository: ImageRepository(
          store: ImageStore(directory: Directory('${tempDir.path}/images')),
        ),
        storageDirectory: tempDir,
      );
      list = DocumentListNotifier(documentStorage: storage);
    });

    tearDown(() async {
      list.dispose();
      await tempDir.delete(recursive: true);
    });

    test('is empty until refreshed', () async {
      await storage.saveDocument('doc_a', Document(), 'A');
      expect(list.documents, isEmpty);

      await list.refresh();
      expect(list.documents.map((doc) => doc.name), ['A']);
    });

    test('notifies listeners on refresh', () async {
      var notifications = 0;
      list.addListener(() => notifications++);

      await list.refresh();

      expect(notifications, 1);
    });

    test('exposes an unmodifiable list', () async {
      await list.refresh();
      expect(() => list.documents.clear(), throwsUnsupportedError);
    });
  });
}
