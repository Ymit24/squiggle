import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/app/app_router.dart';
import 'package:squiggle_flutter/app/squiggle_app.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/editor_page.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/active_document_coordinator.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

import '../support/test_database.dart';

void main() {
  testWidgets(
    'opens a document from the library and saves edits to the database',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late AppDatabase database;
      late ActiveDocumentCoordinator active;
      late DocumentListNotifier list;
      final context = EditorContext(document: Document());
      await tester.runAsync(() async {
        database = createTestDatabase();
        await database.documentsDao.create(name: 'Sketch');
        list = DocumentListNotifier(documentsDao: database.documentsDao);
        active = ActiveDocumentCoordinator(
          documentsDao: database.documentsDao,
          appStateDao: database.appStateDao,
          documentList: list,
          context: context,
        );
        await active.initialize();
      });

      await tester.pumpWidget(
        SquiggleApp(
          appRouter: AppRouter(),
          imageRepository: ImageRepository(images: database.imagesDao),
          context: context,
          database: database,
          documentList: list,
          activeDocument: active,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sketch'), findsOneWidget);
      expect(find.text('Untitled'), findsNothing);

      await _openFromLibrary(tester, 'Sketch');
      final opened = await _first(tester, database);
      expect(active.activeId, opened.id);

      context.history.run('Add feature', (transaction) {
        transaction.add(
          Feature(
            origin: Offset.zero,
            size: const Size(10, 10),
            kind: FeatureKindRectangle(),
          ),
        );
      });
      final saved = await tester.runAsync(() async {
        await active.flush();
        return database.documentsDao.load(opened.id);
      });
      expect(saved!.nodes, hasLength(1));

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.runAsync(() async {
        await database.close();
      });
      context.dispose();
    },
  );
  testWidgets('asks before leaving a canvas whose changes could not be saved', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late AppDatabase database;
    late ActiveDocumentCoordinator active;
    late DocumentListNotifier list;
    final context = EditorContext(document: Document());
    await tester.runAsync(() async {
      database = createTestDatabase();
      final sketch = await database.documentsDao.create(name: 'Sketch');
      list = DocumentListNotifier(documentsDao: database.documentsDao);
      active = ActiveDocumentCoordinator(
        documentsDao: database.documentsDao,
        appStateDao: database.appStateDao,
        documentList: list,
        context: context,
      );
      await active.initialize();
      await active.openDocument(sketch.id);
    });

    final router = AppRouter();
    await tester.pumpWidget(
      SquiggleApp(
        appRouter: router,
        imageRepository: ImageRepository(images: database.imagesDao),
        context: context,
        database: database,
        documentList: list,
        activeDocument: active,
      ),
    );
    await tester.pumpAndSettle();
    await _openFromLibrary(tester, 'Sketch');

    // The database answers in real time, so alternate real waits with pumps
    // until a tap's queries and the UI they lead to have settled.
    Future<void> tapAndSettle(Finder target) async {
      await tester.tap(target);
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.pumpAndSettle();
    }

    final originalOnError = FlutterError.onError;
    final reported = <FlutterErrorDetails>[];
    FlutterError.onError = reported.add;
    try {
      // No image row has this hash, so every save fails on the image_refs FK.
      context.history.run('Add image', (transaction) {
        transaction.add(
          Feature(
            origin: Offset.zero,
            size: const Size(10, 10),
            kind: FeatureKindImage('missing-hash'),
          ),
        );
      });
      await tapAndSettle(find.byTooltip('Canvas library'));
      expect(find.text("Couldn't save this canvas"), findsOneWidget);

      await tapAndSettle(find.text('Keep editing'));
      expect(find.byType(EditorPage), findsOneWidget);
      expect(context.document.nodes, hasLength(1));

      await tapAndSettle(find.byTooltip('Canvas library'));
      await tapAndSettle(find.text('Leave without saving'));
      expect(find.text("Couldn't save this canvas"), findsNothing);
      expect(find.text('Sketch'), findsOneWidget);
      expect(active.activeId, isNull);
    } finally {
      FlutterError.onError = originalOnError;
    }
    // Only the failed saves were reported, nothing from the UI.
    expect(
      reported.map((details) => details.exception.toString()),
      allOf(isNotEmpty, everyElement(contains('FOREIGN KEY'))),
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(() async {
      await database.close();
    });
    context.dispose();
  });
}

Future<DocumentInfo> _first(WidgetTester tester, AppDatabase database) async =>
    (await tester.runAsync(() => database.documentsDao.list()))!.first;

/// Library cards also handle double taps, so a single tap only fires once the
/// double-tap window has passed.
Future<void> _openFromLibrary(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await tester.pump(kDoubleTapTimeout);
  await tester.pumpAndSettle();
  expect(find.byType(EditorPage), findsOneWidget);
}
