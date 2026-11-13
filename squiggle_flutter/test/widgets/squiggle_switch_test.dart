import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_switch.dart';

void main() {
  Future<List<bool>> pumpSwitch(
    WidgetTester tester, {
    bool value = false,
    bool enabled = true,
  }) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Center(
          child: SquiggleSwitch(
            value: value,
            onChanged: enabled ? changes.add : null,
          ),
        ),
      ),
    );
    return changes;
  }

  testWidgets('tapping reports the opposite value', (tester) async {
    final changes = await pumpSwitch(tester, value: true);

    await tester.tap(find.byType(SquiggleSwitch));

    expect(changes, [false]);
  });

  testWidgets('space toggles the focused switch', (tester) async {
    final changes = await pumpSwitch(tester);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);

    expect(changes, [true]);
  });

  testWidgets('a disabled switch ignores taps and reports its state', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    final changes = await pumpSwitch(tester, value: true, enabled: false);

    await tester.tap(find.byType(SquiggleSwitch));

    expect(changes, isEmpty);
    expect(
      tester.getSemantics(find.byType(SquiggleSwitch)),
      isSemantics(
        hasToggledState: true,
        isToggled: true,
        hasEnabledState: true,
      ),
    );
    handle.dispose();
  });
}
