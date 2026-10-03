import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_context_menu.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_panel.dart';
import 'package:squiggle_flutter/widgets/squiggle_shortcut_hint.dart';

void main() {
  for (final platform in [TargetPlatform.macOS, TargetPlatform.windows]) {
    testWidgets('context menu fits labels and aligns $platform shortcuts', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1000, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final labels = ['Undo', 'Bring backward', 'Send to Back'];
      final shortcuts = ['⌘Z', '⌘[', '⌘⌥['];
      await tester.pumpWidget(
        MaterialApp(
          theme: SquiggleThemeData.dark().copyWith(platform: platform),
          home: Scaffold(
            body: Stack(
              children: [
                SquiggleContextMenu(
                  position: const Offset(990, 890),
                  children: [
                    for (var i = 0; i < labels.length; i++)
                      SquiggleMenuItem(
                        label: labels[i],
                        shortcut: shortcuts[i],
                        icon: Icons.layers,
                        onPressed: () {},
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in labels) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          paragraph.size.width,
          greaterThanOrEqualTo(paragraph.getMaxIntrinsicWidth(double.infinity)),
        );
      }
      final hints = find.byType(SquiggleShortcutHint);
      final rightEdges = [
        for (var i = 0; i < hints.evaluate().length; i++)
          tester.getRect(hints.at(i)).right,
      ];
      for (final edge in rightEdges) {
        expect(edge, closeTo(rightEdges.first, 0.01));
      }
      final panel = tester.getRect(find.byType(SquiggleMenuPanel));
      expect(panel.right, lessThanOrEqualTo(1000));
      expect(panel.bottom, lessThanOrEqualTo(900));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('checked menu action retains label and shortcut space', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SquiggleMenuPanel(
              children: [
                SquiggleMenuItem(
                  label: 'Last edited',
                  icon: Icons.schedule,
                  shortcut: '⌘1',
                  checked: true,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final label = tester.renderObject<RenderParagraph>(
      find.text('Last edited'),
    );
    expect(label.didExceedMaxLines, isFalse);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
