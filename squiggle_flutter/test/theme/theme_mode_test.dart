import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/app/app_router.dart';
import 'package:squiggle_flutter/app/squiggle_app.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/document_library/widgets/library_top_bar.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/preferences/widgets/appearance_section.dart';
import 'package:squiggle_flutter/repositories/active_document_coordinator.dart';
import 'package:squiggle_flutter/repositories/document_list_notifier.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/theme/theme_mode_preference.dart';

import '../support/test_database.dart';
import '../support/test_preferences.dart';

void main() {
  test('the light ThemeData carries the light Squiggle tokens', () {
    final light = SquiggleThemeData.light();

    expect(light.brightness, Brightness.light);
    expect(light.extension<SquiggleTheme>()!.colors, SquiggleColorScheme.light);
    expect(light.scaffoldBackgroundColor, SquiggleColorScheme.light.base);
    expect(SquiggleThemeData.dark().brightness, Brightness.dark);
  });

  testWidgets('the Appearance section selects the theme mode', (tester) async {
    final preferences = testPreferences();
    await tester.pumpWidget(
      withPreferences(
        MaterialApp(
          theme: SquiggleThemeData.dark(),
          home: const Scaffold(body: AppearanceSection()),
        ),
        preferences,
      ),
    );

    expect(preferences.get(themeModePreference), ThemeMode.dark);
    await tester.tap(find.text('Light'));
    await tester.pump();
    expect(preferences.get(themeModePreference), ThemeMode.light);
    await tester.tap(find.text('System'));
    await tester.pump();
    expect(preferences.get(themeModePreference), ThemeMode.system);
  });

  testWidgets('the app follows the saved theme mode', (tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late AppDatabase database;
    late ActiveDocumentCoordinator active;
    late DocumentListNotifier list;
    final context = EditorContext(document: Document());
    await tester.runAsync(() async {
      database = createTestDatabase();
      list = DocumentListNotifier(documentsDao: database.documentsDao);
      active = ActiveDocumentCoordinator(
        documentsDao: database.documentsDao,
        appStateDao: database.appStateDao,
        documentList: list,
        context: context,
      );
      await active.initialize();
    });
    final preferences = testPreferences({themeModePreference.key: 'light'});
    await tester.pumpWidget(
      SquiggleApp(
        appRouter: AppRouter(),
        imageRepository: ImageRepository(images: database.imagesDao),
        context: context,
        database: database,
        documentList: list,
        activeDocument: active,
        preferences: preferences,
      ),
    );
    await tester.pumpAndSettle();
    SquiggleColorScheme colors() =>
        tester.element(find.byType(LibraryTopBar)).squiggleTheme.colors;

    expect(colors(), SquiggleColorScheme.light);

    await tester.runAsync(
      () => preferences.set(themeModePreference, ThemeMode.dark),
    );
    await tester.pumpAndSettle();
    expect(colors(), SquiggleColorScheme.dark);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.runAsync(database.close);
    context.dispose();
  });
}
