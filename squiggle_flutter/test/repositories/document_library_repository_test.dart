import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/document_library_repository_impl.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DocumentLibraryRepository', () {
    late Directory tempDir;
    late DocumentLibraryRepositoryImpl library;
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
      library = DocumentLibraryRepositoryImpl(
        documentStorage: documentStorage,
        context: context,
      );
      await library.initialize();
    });

    tearDown(() async {
      library.dispose();
      // Let queued autosaves finish before removing their storage directory.
      await library.documentStorage.loadDocument(library.currentDocument!.id);
      context.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'session-only changes autosave and stay local to each document',
      () async {
        final firstId = library.currentDocument!.id;
        final brush = context.brushes.create('Construction');
        context.brushes.setField('strokeWidth', 3.0);
        // Loading waits for the queued autosave, with no explicit save call.
        final saved = (await library.documentStorage.loadDocument(
          firstId,
        ))!.document;
        expect(saved.session.activeBrushId, brush.id);
        expect(saved.session.activeBrush.values['strokeWidth'], 3.0);
        expect(context.history.canUndo, isFalse);
        final other = context.brushes.create('Actual');
        context.brushes.activate(brush.id);
        context.brushes.move(brush.id, toIndex: 2);
        final reordered = (await library.documentStorage.loadDocument(
          firstId,
        ))!.document;
        expect(reordered.session.brushes.map((profile) => profile.id), [
          'scratch',
          other.id,
          brush.id,
        ]);
        expect(reordered.session.activeBrushId, brush.id);
        await library.createDocument(name: 'Other');
        expect(context.brushes.active.isScratch, isTrue);
        expect(context.brushes.active.values, isEmpty);
        await library.openDocument(firstId);
        expect(context.brushes.active.id, brush.id);
        expect(context.brushes.active.values['strokeWidth'], 3.0);
      },
    );

    test('switches documents and clears selection', () async {
      await library.createDocument(name: 'One');
      context.history.run('Add feature', (transaction) {
        transaction.add(
          Feature(
            origin: const Offset(0, 0),
            size: const Size(10, 10),
            kind: FeatureKindRectangle(),
          ),
        );
      });
      context.selection.selectNode(context.document.nodes.first.id);
      expect(context.document.nodes, hasLength(1));
      expect(context.selection.selectedNodeIds, hasLength(1));

      await library.createDocument(name: 'Two');
      expect(library.currentDocument?.name, 'Two');
      expect(context.document.nodes, isEmpty);
      expect(context.selection.selectedNodeIds, isEmpty);

      final one = library.documents.firstWhere((doc) => doc.name == 'One');
      await library.openDocument(one.id);
      expect(library.currentDocument?.name, 'One');
      expect(context.document.nodes, hasLength(1));
    });

    test('does not delete the last remaining document', () async {
      expect(library.documents, hasLength(1));
      await library.deleteDocument(library.documents.first.id);
      expect(library.documents, hasLength(1));
    });
  });
}
