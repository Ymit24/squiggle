import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/preferences/preferences_panel.dart';
import 'package:squiggle_flutter/preferences/widgets/preferences_button.dart';
import 'package:squiggle_flutter/preferences/widgets/preferences_dialog.dart';
import 'package:squiggle_flutter/preferences/widgets/preferences_shortcuts.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

void main() {
  setUp(
    () => PackageInfo.setMockInitialValues(
      appName: 'Squiggle',
      packageName: 'squiggle_flutter',
      version: '1.2.3',
      buildNumber: '45',
      buildSignature: '',
    ),
  );

  Future<PreferencesPanel> pumpApp(WidgetTester tester) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    final panel = PreferencesPanel(navigatorKey: navigatorKey);
    await tester.pumpWidget(
      Provider.value(
        value: panel,
        child: MaterialApp(
          navigatorKey: navigatorKey,
          theme: SquiggleThemeData.dark(),
          builder: (context, child) => PreferencesShortcuts(child: child!),
          home: const Scaffold(body: Center(child: PreferencesButton())),
        ),
      ),
    );
    return panel;
  }

  Future<void> pressShortcut(
    WidgetTester tester,
    LogicalKeyboardKey modifier,
  ) async {
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(LogicalKeyboardKey.comma);
    await tester.sendKeyUpEvent(modifier);
    await tester.pumpAndSettle();
  }

  testWidgets('the gear button opens the dialog and Done closes it', (
    tester,
  ) async {
    final panel = await pumpApp(tester);

    await tester.tap(find.byTooltip('Preferences  Ctrl+,'));
    await tester.pumpAndSettle();
    expect(find.byType(PreferencesDialog), findsOneWidget);
    expect(find.text('Version 1.2.3+45'), findsOneWidget);
    expect(panel.isOpen, isTrue);

    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    expect(find.byType(PreferencesDialog), findsNothing);
    expect(panel.isOpen, isFalse);
  });

  testWidgets('Ctrl+, and Cmd+, toggle the dialog', (tester) async {
    await pumpApp(tester);

    await pressShortcut(tester, LogicalKeyboardKey.controlLeft);
    expect(find.byType(PreferencesDialog), findsOneWidget);
    await pressShortcut(tester, LogicalKeyboardKey.controlLeft);
    expect(find.byType(PreferencesDialog), findsNothing);

    await pressShortcut(tester, LogicalKeyboardKey.metaLeft);
    expect(find.byType(PreferencesDialog), findsOneWidget);
    await pressShortcut(tester, LogicalKeyboardKey.metaLeft);
    expect(find.byType(PreferencesDialog), findsNothing);
  });

  testWidgets('opening twice shows a single dialog', (tester) async {
    final panel = await pumpApp(tester);

    panel.open();
    panel.open();
    await tester.pumpAndSettle();

    expect(find.byType(PreferencesDialog), findsOneWidget);
  });

  testWidgets('Escape closes the dialog', (tester) async {
    final panel = await pumpApp(tester);
    panel.open();
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(find.byType(PreferencesDialog), findsNothing);
    expect(panel.isOpen, isFalse);
  });
}
