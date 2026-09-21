import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle_pressable.dart';

void main() {
  testWidgets('renders labeled content and invokes onPressed', (tester) async {
    var presses = 0;

    await tester.pumpWidget(
      _app(
        SquiggleButton(
          label: 'Create',
          leading: const Icon(Icons.add),
          trailing: const Icon(Icons.arrow_forward),
          onPressed: () => presses++,
        ),
      ),
    );

    expect(find.text('Create'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

    await tester.tap(find.byType(SquiggleButton));
    expect(presses, 1);
  });

  testWidgets('icon button supplies a tooltip and square hit target', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        SquiggleButton.icon(
          icon: const Icon(Icons.close),
          tooltip: 'Close',
          onPressed: () {},
        ),
      ),
    );

    expect(tester.widget<Tooltip>(find.byType(Tooltip)).message, 'Close');
    final container = find.descendant(
      of: find.byType(SquigglePressable),
      matching: find.byType(AnimatedContainer),
    );
    expect(container, findsOneWidget);
    expect(tester.getSize(container), const Size(38, 38));
  });

  testWidgets('disabled button ignores presses', (tester) async {
    await tester.pumpWidget(
      _app(SquiggleButton(label: 'Disabled', onPressed: null)),
    );

    expect(
      tester
          .widget<SquigglePressable>(find.byType(SquigglePressable))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byType(SquiggleButton));
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: SquiggleThemeData.dark(),
    home: Scaffold(body: Center(child: child)),
  );
}
