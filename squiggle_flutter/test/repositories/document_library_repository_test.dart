import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentLibraryRepository', () {
    late Directory tempDir;
    late DocumentLibraryRepository library;
    late EditorContext context;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('squiggle_library_');
      final imageRepository = ImageRepository(
        imagesDirectory: Directory('${tempDir.path}/images'),
      );
      await imageRepository.initialize();
      final documentStorage = DocumentStorage(
        imageRepository: imageRepository,
        storageDirectory: tempDir,
      );
      context = EditorContext(document: Document());
      library = DocumentLibraryRepository(
        documentStorage: documentStorage,
        context: context,
      );
      await library.initialize();
    });

    tearDown(() async {
      library.dispose();
      context.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('switches documents and clears selection', () async {
      await library.createDocument(name: 'One');
      context.execute(
        AddFeatureCommand(
          Feature(
            origin: const Offset(0, 0),
            size: const Size(10, 10),
            kind: const FeatureKindRectangle(),
          ),
        ),
      );
      context.selection.selectFeature(context.document.features.first.id);
      expect(context.document.features, hasLength(1));
      expect(context.selection.selectedFeatures, hasLength(1));

      await library.createDocument(name: 'Two');
      expect(library.currentDocument?.name, 'Two');
      expect(context.document.features, isEmpty);
      expect(context.selection.selectedFeatures, isEmpty);

      final one = library.documents.firstWhere((doc) => doc.name == 'One');
      await library.openDocument(one.id);
      expect(library.currentDocument?.name, 'One');
      expect(context.document.features, hasLength(1));
    });

    test('does not delete the last remaining document', () async {
      expect(library.documents, hasLength(1));
      await library.deleteDocument(library.documents.first.id);
      expect(library.documents, hasLength(1));
    });
  });
}
