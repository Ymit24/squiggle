import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/app/app_router.dart';
import 'package:squiggle_flutter/app/squiggle_app.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
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

      await tester.tap(find.text('Sketch'));
      await tester.pumpAndSettle();
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
}

Future<DocumentInfo> _first(WidgetTester tester, AppDatabase database) async =>
    (await tester.runAsync(() => database.documentsDao.list()))!.first;
