import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

void main() {
  testWidgets('ghost button is borderless and uses the shared disabled style', (
    tester,
  ) async {
    var presses = 0;
    final colors = SquiggleTheme.dark.colors;

    Widget button(VoidCallback? onPressed) => MaterialApp(
      theme: SquiggleThemeData.dark(),
      home: Scaffold(
        body: Center(
          child: SquiggleButton(
            onPressed: onPressed,
            label: 'Cancel',
            variant: SquiggleButtonVariant.ghost,
          ),
        ),
      ),
    );

    await tester.pumpWidget(button(() => presses++));
    final enabled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(enabled.style!.backgroundColor!.resolve({}), Colors.transparent);
    expect(enabled.style!.foregroundColor!.resolve({}), colors.subtext0);
    expect(enabled.style!.side, isNull);
    expect(enabled.style!.textStyle!.resolve({})!.fontWeight, FontWeight.w600);
    expect(enabled.style!.minimumSize!.resolve({}), const Size(0, 38));

    await tester.tap(find.text('Cancel'));
    expect(presses, 1);

    await tester.pumpWidget(button(null));
    final disabled = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(disabled.onPressed, isNull);
    expect(
      disabled.style!.backgroundColor!.resolve({WidgetState.disabled}),
      colors.surface0,
    );
    expect(
      disabled.style!.foregroundColor!.resolve({WidgetState.disabled}),
      colors.subtext0.withValues(alpha: 0.5),
    );
    await tester.tap(find.text('Cancel'));
    expect(presses, 1);
  });
}
