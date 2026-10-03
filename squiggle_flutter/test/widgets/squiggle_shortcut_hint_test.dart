import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';
import 'package:squiggle_flutter/widgets/squiggle_shortcut_hint.dart';

void main() {
  testWidgets('shortcut hints adapt modifier notation to the platform', (
    tester,
  ) async {
    for (final platform in [
      TargetPlatform.macOS,
      TargetPlatform.iOS,
      TargetPlatform.windows,
      TargetPlatform.linux,
    ]) {
      await tester.pumpWidget(
        MaterialApp(
          theme: SquiggleThemeData.dark().copyWith(platform: platform),
          home: const Scaffold(body: SquiggleShortcutHint(label: '⇧⌘1')),
        ),
      );
      await tester.pumpAndSettle();
      final macStyle =
          platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
      expect(find.text(macStyle ? '⇧⌘1' : 'Shift+Ctrl+1'), findsOneWidget);
    }
  });

  testWidgets('menu items reuse hint styling and retain disabled state', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark().copyWith(
          platform: TargetPlatform.macOS,
        ),
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: Column(
              children: [
                SquiggleMenuItem(
                  label: 'Undo',
                  shortcut: '⌘Z',
                  onPressed: () {},
                ),
                const SquiggleMenuItem(
                  label: 'Redo',
                  shortcut: '⇧⌘Z',
                  onPressed: null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final hints = tester
        .widgetList<SquiggleShortcutHint>(find.byType(SquiggleShortcutHint))
        .toList();
    expect(hints.map((hint) => hint.enabled), [true, false]);
    expect(find.text('⌘Z'), findsOneWidget);
    expect(find.text('⇧⌘Z'), findsOneWidget);
  });
}
