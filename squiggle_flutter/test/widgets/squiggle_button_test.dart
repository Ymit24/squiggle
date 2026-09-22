import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/squiggle_color_scheme.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

void main() {
  Widget buildButton({required VoidCallback? onPressed}) => MaterialApp(
    theme: SquiggleThemeData.dark(),
    home: Scaffold(
      body: Center(
        child: SquiggleButton(
          onPressed: onPressed,
          label: 'Delete',
          variant: SquiggleButtonVariant.danger,
        ),
      ),
    ),
  );

  testWidgets('danger variant uses danger colors and bold label', (
    tester,
  ) async {
    await tester.pumpWidget(buildButton(onPressed: () {}));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.style!.backgroundColor!.resolve({}), squiggleOnDangerColor);
    expect(button.style!.foregroundColor!.resolve({}), Colors.white);
    expect(find.text('Delete'), findsOneWidget);
  });

  testWidgets('danger variant is disabled when onPressed is null', (
    tester,
  ) async {
    await tester.pumpWidget(buildButton(onPressed: null));

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(
      button.style!.backgroundColor!.resolve({WidgetState.disabled}),
      SquiggleColorScheme.dark.surface0,
    );
  });
}
