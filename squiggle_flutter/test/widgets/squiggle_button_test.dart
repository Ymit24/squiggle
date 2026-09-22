import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

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
    expect(tester.getSize(find.byType(TextButton)), const Size(38, 38));
  });

  testWidgets('disabled button ignores presses', (tester) async {
    await tester.pumpWidget(
      _app(SquiggleButton(label: 'Disabled', onPressed: null)),
    );

    expect(
      tester.widget<TextButton>(find.byType(TextButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(SquiggleButton));
  });

  testWidgets('exposes a semantic tap action', (tester) async {
    await tester.pumpWidget(
      _app(SquiggleButton(label: 'Create', onPressed: () {})),
    );

    expect(
      tester.getSemantics(find.text('Create')),
      matchesSemantics(
        label: 'Create',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
  });
}

Widget _app(Widget child) {
  return MaterialApp(
    theme: SquiggleThemeData.dark(),
    home: Scaffold(body: Center(child: child)),
  );
}
