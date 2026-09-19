import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_button.dart';

void main() {
  testWidgets('renders primary, secondary, danger, and ghost variants', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Scaffold(
          body: Column(
            children: [
              SquiggleButton(onPressed: () {}, label: 'Primary'),
              SquiggleButton(
                onPressed: () {},
                label: 'Secondary',
                variant: SquiggleButtonVariant.secondary,
              ),
              SquiggleButton(
                onPressed: () {},
                label: 'Danger',
                variant: SquiggleButtonVariant.danger,
              ),
              SquiggleButton(
                onPressed: () {},
                label: 'Ghost',
                variant: SquiggleButtonVariant.ghost,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(FilledButton), findsNWidgets(3));
    expect(find.byType(TextButton), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compact button remains square and exposes its tooltip', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Scaffold(
          body: SquiggleButton(
            onPressed: () {},
            icon: Icons.add,
            size: SquiggleButtonSize.compact,
            tooltip: 'Add canvas',
          ),
        ),
      ),
    );

    expect(find.byTooltip('Add canvas'), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)), const Size.square(38));
  });
}
