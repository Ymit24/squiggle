import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_keycap.dart';

void main() {
  Future<void> pumpKeycap(WidgetTester tester, TargetPlatform platform) =>
      tester.pumpWidget(
        MaterialApp(
          theme: SquiggleThemeData.dark().copyWith(platform: platform),
          home: const Center(child: SquiggleKeycap(label: "⌘'")),
        ),
      );

  testWidgets('keeps symbols on macOS and spells modifiers elsewhere', (
    tester,
  ) async {
    await pumpKeycap(tester, TargetPlatform.macOS);
    expect(find.text("⌘'"), findsOneWidget);

    await pumpKeycap(tester, TargetPlatform.linux);
    await tester.pumpAndSettle();
    expect(find.text("Ctrl+'"), findsOneWidget);
  });
}
