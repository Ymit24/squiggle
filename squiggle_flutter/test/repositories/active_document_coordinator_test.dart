import 'dart:ui';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/active_document_coordinator.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';

import '../support/test_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ActiveDocumentCoordinator', () {
    late AppDatabase database;
    late DocumentListNotifier documentList;
    late ActiveDocumentCoordinator active;
    late EditorContext context;

    setUp(() async {
      database = createTestDatabase();
      context = EditorContext(document: Document());
      documentList = DocumentListNotifier(documentsDao: database.documentsDao);
      active = ActiveDocumentCoordinator(
        documentsDao: database.documentsDao,
        appStateDao: database.appStateDao,
        documentList: documentList,
        context: context,
      );
      await active.initialize();
    });

    tearDown(() async {
      active.dispose();
      documentList.dispose();
      // Let queued autosaves finish before closing the database.
      await active.flush();
      context.dispose();
      await database.close();
    });

    Future<Document> stored(String id) async =>
        Document.fromDataModel((await database.documentsDao.load(id))!);

    test(
      'session-only changes autosave and stay local to each document',
      () async {
        final firstId = active.activeId!;
        final brush = context.brushes.create('Construction');
        context.brushes.setField('strokeWidth', 3.0);
        // Autosave runs without an explicit save; flush only waits for it.
        await active.flush();
        final saved = await stored(firstId);
        expect(saved.session.activeBrushId, brush.id);
        expect(saved.session.activeBrush.values['strokeWidth'], 3.0);
        expect(context.history.canUndo, isFalse);
        final other = context.brushes.create('Actual');
        context.brushes.activate(brush.id);
        context.brushes.move(brush.id, toIndex: 2);
        await active.flush();
        final reordered = await stored(firstId);
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
        final saved = await stored(id);
        expect(saved.nodes, hasLength(1));
      },
    );

    test('rename updates the list and later autosaves keep the name', () async {
      final id = active.activeId!;
      await active.renameDocument(id, '  Renamed  ');
      expect(documentList.documents.single.name, 'Renamed');

      context.brushes.create('Construction');
      await active.flush();
      await documentList.refresh();
      expect(documentList.documents.single.name, 'Renamed');
      expect((await stored(id)).name, 'Renamed');
    });

    test('new documents get the next free Untitled name', () async {
      expect(documentList.documents.single.name, 'Untitled');

      final created = await active.createDocument();

      expect(created.name, 'Untitled 2');
    });

    test('a new coordinator resumes the last active document', () async {
      final second = await active.createDocument(name: 'Second');

      final resumed = ActiveDocumentCoordinator(
        documentsDao: database.documentsDao,
        appStateDao: database.appStateDao,
        documentList: DocumentListNotifier(documentsDao: database.documentsDao),
        context: EditorContext(document: Document()),
      );
      addTearDown(resumed.dispose);
      await resumed.initialize();

      expect(resumed.activeId, second.id);
    });

    test('a burst of edits ends with the latest state saved', () async {
      final id = active.activeId!;
      for (var i = 0; i < 20; i++) {
        context.history.run('Add feature', (transaction) {
          transaction.add(
            Feature(
              origin: Offset(i.toDouble(), 0),
              size: const Size(10, 10),
              kind: FeatureKindRectangle(),
            ),
          );
        });
      }
      await active.flush();

      expect((await stored(id)).nodes, hasLength(20));
    });

    test(
      'an unreadable document is left untouched and not autosaved',
      () async {
        final broken = await database.documentsDao.create(name: 'Broken');
        await (database.update(database.documentBodies)
              ..where((t) => t.documentId.equals(broken.id)))
            .write(const DocumentBodiesCompanion(body: Value('not json')));
        await documentList.refresh();

        final originalOnError = FlutterError.onError;
        final reported = <FlutterErrorDetails>[];
        FlutterError.onError = reported.add;
        try {
          await active.openDocument(broken.id);
          expect(active.loadError, isNotNull);
          expect(reported, hasLength(1));
          expect(context.document.nodes, isEmpty);

          context.brushes.create('Construction');
          await active.flush();
        } finally {
          FlutterError.onError = originalOnError;
        }

        final row = await (database.select(
          database.documentBodies,
        )..where((t) => t.documentId.equals(broken.id))).getSingle();
        expect(row.body, 'not json');

        final other = documentList.documents.firstWhere(
          (doc) => doc.id != broken.id,
        );
        await active.openDocument(other.id);
        expect(active.loadError, isNull);
        context.brushes.create('Actual');
        await active.flush();
        expect((await stored(other.id)).session.brushes, hasLength(2));
      },
    );

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
