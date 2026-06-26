import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentLibraryRepository', () {
    late Directory tempDir;
    late DocumentLibraryRepository library;
    late DocumentRepository documentRepository;
    late SelectionRepository selectionRepository;

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
      documentRepository = DocumentRepository(document: Document());
      selectionRepository = SelectionRepository();
      library = DocumentLibraryRepository(
        documentStorage: documentStorage,
        documentRepository: documentRepository,
        selectionRepository: selectionRepository,
      );
      await library.initialize();
    });

    tearDown(() async {
      library.dispose();
      documentRepository.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('switches documents and clears selection', () async {
      await library.createDocument(name: 'One');
      documentRepository.executeCommand(
        AddFeatureCommand(
          Feature(
            origin: const Offset(0, 0),
            size: const Size(10, 10),
            kind: const FeatureKindRectangle(),
          ),
        ),
      );
      selectionRepository.selectFeature(documentRepository.document.features.first.id);
      expect(documentRepository.document.features, hasLength(1));
      expect(selectionRepository.selectedFeatures, hasLength(1));

      await library.createDocument(name: 'Two');
      expect(library.currentDocument?.name, 'Two');
      expect(documentRepository.document.features, isEmpty);
      expect(selectionRepository.selectedFeatures, isEmpty);

      final one = library.documents.firstWhere((doc) => doc.name == 'One');
      await library.openDocument(one.id);
      expect(library.currentDocument?.name, 'One');
      expect(documentRepository.document.features, hasLength(1));
    });

    test('does not delete the last remaining document', () async {
      expect(library.documents, hasLength(1));
      await library.deleteDocument(library.documents.first.id);
      expect(library.documents, hasLength(1));
    });
  });
}
