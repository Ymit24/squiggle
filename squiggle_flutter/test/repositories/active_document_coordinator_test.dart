import 'dart:async';
import 'dart:ui';

import 'package:data_models/data_models.dart' as data;

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/database/daos/documents_dao.dart';
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
      'flush persists a document loaded into the context directly',
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
    test('opening a document does not rewrite it or bump updatedAt', () async {
      var now = DateTime.utc(2026);
      final timedDatabase = AppDatabase(
        NativeDatabase.memory(),
        clock: () => now = now.add(const Duration(minutes: 1)),
      );
      addTearDown(timedDatabase.close);
      final timedContext = EditorContext(document: Document());
      addTearDown(timedContext.dispose);
      final timedList = DocumentListNotifier(
        documentsDao: timedDatabase.documentsDao,
      );
      addTearDown(timedList.dispose);
      final timed = ActiveDocumentCoordinator(
        documentsDao: timedDatabase.documentsDao,
        appStateDao: timedDatabase.appStateDao,
        documentList: timedList,
        context: timedContext,
      );
      addTearDown(timed.dispose);
      await timed.initialize();
      final firstId = timed.activeId!;
      await timed.createDocument(name: 'Second');
      Future<List<(String, DateTime)>> timestamps() async => [
        for (final doc in await timedDatabase.documentsDao.list())
          (doc.id, doc.updatedAt),
      ];
      final before = await timestamps();

      await timed.openDocument(firstId);
      // Give any autosave the open might have queued a chance to run.
      await pumpEventQueue();

      expect(await timestamps(), before);
    });

    test(
      'an edit during a switch is saved to the document it was made on',
      () async {
        // A context of its own, so the setUp coordinator does not see it.
        final gatedContext = EditorContext(document: Document());
        addTearDown(gatedContext.dispose);
        final gated = _GatedDocumentsDao(database);
        final gatedActive = ActiveDocumentCoordinator(
          documentsDao: gated,
          appStateDao: database.appStateDao,
          documentList: documentList,
          context: gatedContext,
        );
        addTearDown(gatedActive.dispose);
        await gatedActive.initialize();
        final firstId = gatedActive.activeId!;

        final broken = await database.documentsDao.create(name: 'Broken');
        await (database.update(database.documentBodies)
              ..where((t) => t.documentId.equals(broken.id)))
            .write(const DocumentBodiesCompanion(body: Value('not json')));
        await documentList.refresh();

        final originalOnError = FlutterError.onError;
        FlutterError.onError = (_) {};
        try {
          gated.gate = Completer<void>();
          final opening = gatedActive.openDocument(broken.id);
          await gated.loadStarted.future;
          gatedContext.history.run('Add feature', (transaction) {
            transaction.add(
              Feature(
                origin: const Offset(0, 0),
                size: const Size(10, 10),
                kind: FeatureKindRectangle(),
              ),
            );
          });
          gated.gate!.complete();
          await opening;
          await gatedActive.flush();
          await Future<void>.delayed(Duration.zero);
        } finally {
          FlutterError.onError = originalOnError;
        }

        expect(gatedActive.loadError, isNotNull);
        final row = await (database.select(
          database.documentBodies,
        )..where((t) => t.documentId.equals(broken.id))).getSingle();
        expect(row.body, 'not json');
        expect((await stored(firstId)).nodes, hasLength(1));
      },
    );

    test(
      'a failed save makes flush throw until the document is discarded',
      () async {
        final originalOnError = FlutterError.onError;
        final reported = <FlutterErrorDetails>[];
        FlutterError.onError = reported.add;
        try {
          // No image row with this hash exists, so the image_refs FK fails.
          context.history.run('Add image', (transaction) {
            transaction.add(
              Feature(
                origin: const Offset(0, 0),
                size: const Size(10, 10),
                kind: FeatureKindImage('missing-hash'),
              ),
            );
          });
          await expectLater(
            active.flush(),
            throwsA(isA<DocumentSaveException>()),
          );
          expect(reported, isNotEmpty);

          active.discardActiveDocument();
          await active.flush();
          final created = await active.createDocument(name: 'Fresh');
          expect(active.activeId, created.id);
          await active.flush();
        } finally {
          FlutterError.onError = originalOnError;
        }
      },
    );

    test('opening an unknown id reports it as missing', () async {
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await active.openDocument('no-such-id');
      } finally {
        FlutterError.onError = originalOnError;
      }
      expect(active.activeId, 'no-such-id');
      expect(active.loadError, isA<DocumentNotFoundException>());
    });

    test('reopening a document that failed to load retries it', () async {
      final doc = await database.documentsDao.create(name: 'Flaky');
      await (database.update(database.documentBodies)
            ..where((t) => t.documentId.equals(doc.id)))
          .write(const DocumentBodiesCompanion(body: Value('not json')));
      await documentList.refresh();

      final originalOnError = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await active.openDocument(doc.id);
      } finally {
        FlutterError.onError = originalOnError;
      }
      expect(active.loadError, isNotNull);

      await (database.update(
        database.documentBodies,
      )..where((t) => t.documentId.equals(doc.id))).write(
        DocumentBodiesCompanion(
          body: Value(data.Document(name: 'Flaky').encode()),
        ),
      );
      await active.openDocument(doc.id);
      expect(active.loadError, isNull);
    });
  });
}

/// Holds [load] open on [gate] so a test can act while a switch is loading.
class _GatedDocumentsDao extends DocumentsDao {
  _GatedDocumentsDao(super.attachedDatabase);

  Completer<void>? gate;
  final loadStarted = Completer<void>();

  @override
  Future<data.Document?> load(String id) async {
    final pending = gate;
    if (pending != null) {
      if (!loadStarted.isCompleted) loadStarted.complete();
      await pending.future;
    }
    return super.load(id);
  }
}
