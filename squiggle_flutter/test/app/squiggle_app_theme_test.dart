import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/app/app_router.dart';
import 'package:squiggle_flutter/app/squiggle_app.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/active_document_coordinator.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/theme.dart';

import '../support/test_database.dart';

void main() {
  testWidgets('theme preference switches app brightness', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    late AppDatabase database;
    late ActiveDocumentCoordinator active;
    late DocumentListNotifier list;
    final editor = EditorContext(document: Document());
    await tester.runAsync(() async {
      database = createTestDatabase();
      list = DocumentListNotifier(documentsDao: database.documentsDao);
      active = ActiveDocumentCoordinator(
        documentsDao: database.documentsDao,
        appStateDao: database.appStateDao,
        documentList: list,
        context: editor,
      );
      await active.initialize();
      await database.preferencesDao.setValue('themeMode', 'dark');
    });
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await database.close();
      editor.dispose();
    });

    await tester.pumpWidget(
      SquiggleApp(
        appRouter: AppRouter(),
        imageRepository: ImageRepository(images: database.imagesDao),
        context: editor,
        database: database,
        documentList: list,
        activeDocument: active,
      ),
    );
    await tester.pumpAndSettle();

    ThemeData theme() => Theme.of(tester.element(find.byType(Navigator)));
    expect(theme().brightness, Brightness.dark);
    expect(
      theme().extension<SquiggleTheme>()!.colors.base,
      SquiggleColorScheme.dark.base,
    );
    expect(
      theme().extension<SquiggleTheme>()!.colors.canvasBackground,
      SquiggleColorScheme.dark.canvasBackground,
    );

    await tester.runAsync(
      () => database.preferencesDao.setValue('themeMode', 'light'),
    );
    await tester.pumpAndSettle();

    expect(theme().brightness, Brightness.light);
    expect(
      theme().extension<SquiggleTheme>()!.colors.base,
      SquiggleColorScheme.light.base,
    );
    expect(
      theme().extension<SquiggleTheme>()!.colors.canvasBackground,
      SquiggleColorScheme.light.canvasBackground,
    );
  });
}
