import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/preferences_panel.dart';
import 'package:squiggle_flutter/widgets/squiggle_switch.dart';

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

    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
    expect(
      (tester.renderObject(find.text('System')) as RenderBox).size.height,
      lessThan(24),
      reason: 'segment labels stay on one line',
    );

    await tester.tap(find.text('Dark'));
    await tester.pumpAndSettle();

    expect(await database.preferencesDao.getValue('themeMode'), 'dark');
  });

  testWidgets('grid visibility toggle reads and persists the preference', (
    tester,
  ) async {
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await database.close();
    });
    await database.preferencesDao.setValue('grid-lines-visible', 'false');

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

    expect(find.text('Show grid'), findsOneWidget);
    final toggle = find.byType(SquiggleSwitch);
    expect(tester.widget<SquiggleSwitch>(toggle).value, isFalse);
    expect(_namedToggle(toggled: false), findsOneWidget);

    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(
      await database.preferencesDao.getValue('grid-lines-visible'),
      'true',
    );
    expect(tester.widget<SquiggleSwitch>(toggle).value, isTrue);
    expect(_namedToggle(toggled: true), findsOneWidget);
  });

  testWidgets('close button dismisses the panel', (tester) async {
    final database = createTestDatabase();
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await database.close();
    });

    await tester.pumpWidget(
      Provider<AppDatabase>.value(
        value: database,
        child: MaterialApp(
          theme: SquiggleThemeData.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => const PreferencesPanel(),
                ),
                child: const Text('Open settings'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(find.byType(PreferencesPanel), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(PreferencesPanel), findsNothing);
  });
}

Finder _namedToggle({required bool toggled}) => find.byWidgetPredicate(
  (widget) =>
      widget is Semantics &&
      widget.properties.label == 'Show grid' &&
      widget.properties.toggled == toggled,
);
