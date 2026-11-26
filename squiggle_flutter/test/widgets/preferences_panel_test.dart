import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/preferences_panel.dart';

import '../support/test_database.dart';

void main() {
  testWidgets('theme mode selection is persisted', (tester) async {
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await database.close();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Provider<AppDatabase>.value(
          value: database,
          child: const Scaffold(body: PreferencesPanel()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Theme: System'), findsOneWidget);

    await tester.tap(find.text('Theme: System'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(await database.preferencesDao.getValue('themeMode'), 'dark');
    expect(find.text('Theme: Dark'), findsOneWidget);
  });
}
