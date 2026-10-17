import 'dart:io';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/active_document_coordinator.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';
import 'package:squiggle_flutter/repositories/document_storage.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/repositories/image_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActiveDocumentCoordinator', () {
    late Directory tempDir;
    late DocumentStorage documentStorage;
    late DocumentListNotifier documentList;
    late ActiveDocumentCoordinator active;
    late EditorContext context;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('squiggle_library_');
      final imageRepository = ImageRepository(
        store: ImageStore(directory: Directory('${tempDir.path}/images')),
      );
      documentStorage = DocumentStorage(
        imageRepository: imageRepository,
        storageDirectory: tempDir,
      );
      context = EditorContext(document: Document());
      documentList = DocumentListNotifier(documentStorage: documentStorage);
      active = ActiveDocumentCoordinator(
        documentStorage: documentStorage,
        documentList: documentList,
        context: context,
      );
      await active.initialize();
    });

    tearDown(() async {
      active.dispose();
      documentList.dispose();
      // Let queued autosaves finish before removing their storage directory.
      await documentStorage.loadDocument(active.activeId!);
      context.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'session-only changes autosave and stay local to each document',
      () async {
        final firstId = active.activeId!;
        final brush = context.brushes.create('Construction');
        context.brushes.setField('strokeWidth', 3.0);
        // Loading waits for the queued autosave, with no explicit save call.
        final saved = (await documentStorage.loadDocument(firstId))!.document;
        expect(saved.session.activeBrushId, brush.id);
        expect(saved.session.activeBrush.values['strokeWidth'], 3.0);
        expect(context.history.canUndo, isFalse);
        final other = context.brushes.create('Actual');
        context.brushes.activate(brush.id);
        context.brushes.move(brush.id, toIndex: 2);
        final reordered = (await documentStorage.loadDocument(firstId))!
            .document;
        expect(reordered.session.brushes.map((profile) => profile.id), [
          'scratch',
          other.id,
          brush.id,
        ]);
        expect(reordered.session.activeBrushId, brush.id);
        await active.createDocument(name: 'Other');
        expect(context.brushes.active.isScratch, isTrue);
        expect(context.brushes.active.values, isEmpty);
        await active.openDocument(firstId);
        expect(context.brushes.active.id, brush.id);
        expect(context.brushes.active.values['strokeWidth'], 3.0);
      },
    );

    test('switches documents and clears selection', () async {
      await active.createDocument(name: 'One');
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

      await active.createDocument(name: 'Two');
      expect(
        active.activeId,
        documentList.documents.firstWhere((doc) => doc.name == 'Two').id,
      );
      expect(context.document.nodes, isEmpty);
      expect(context.selection.selectedNodeIds, isEmpty);

      final one = documentList.documents.firstWhere((doc) => doc.name == 'One');
      await active.openDocument(one.id);
      expect(active.activeId, one.id);
      expect(context.document.nodes, hasLength(1));
    });

    test('does not delete the last remaining document', () async {
      expect(documentList.documents, hasLength(1));
      await active.deleteDocument(documentList.documents.first.id);
      expect(documentList.documents, hasLength(1));
    });

    test('autosave does not re-read or notify the document list', () async {
      var notifications = 0;
      documentList.addListener(() => notifications++);
      final before = documentList.documents;

      context.brushes.create('Construction');
      context.brushes.setField('strokeWidth', 3.0);
      await active.flush();

      expect(notifications, 0);
      expect(documentList.documents, same(before));
    });

    test(
      'flush persists the active document without a pending autosave',
      () async {
        final id = active.activeId!;
        context.loadDocument(
          Document.fromFeatures([
            Feature(
              origin: const Offset(0, 0),
              size: const Size(10, 10),
              kind: FeatureKindRectangle(),
            ),
          ]),
        );
        await active.flush();
        final saved = (await documentStorage.loadDocument(id))!.document;
        expect(saved.nodes, hasLength(1));
      },
    );

    test('rename updates the list and the name used for later saves', () async {
      final id = active.activeId!;
      await active.renameDocument(id, '  Renamed  ');
      expect(documentList.documents.single.name, 'Renamed');

      context.brushes.create('Construction');
      await active.flush();
      expect(documentList.documents.single.name, 'Renamed');
      await documentList.refresh();
      expect(documentList.documents.single.name, 'Renamed');
    });

    test('deleting the active document opens another one', () async {
      final firstId = active.activeId!;
      await active.createDocument(name: 'Second');
      final secondId = active.activeId!;

      await active.deleteDocument(secondId);

      expect(active.activeId, firstId);
      expect(documentList.documents.map((doc) => doc.id), [firstId]);
    });
  });
}
