import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_segmented_control.dart';

void main() {
  testWidgets('tapping a segment reports its value', (tester) async {
    final handle = tester.ensureSemantics();
    final changes = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: SquiggleThemeData.dark(),
        home: Center(
          child: SizedBox(
            width: 300,
            child: SquiggleSegmentedControl<int>(
              segments: const [
                SquiggleSegment(value: 1, label: 'One', icon: Icons.add),
                SquiggleSegment(value: 2, label: 'Two'),
              ],
              selected: 1,
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Two'));

    expect(changes, [2]);
    expect(
      tester.getSemantics(find.text('One')),
      isSemantics(isSelected: true, isInMutuallyExclusiveGroup: true),
    );
    expect(
      tester.getSemantics(find.text('Two')),
      isSemantics(isSelected: false),
    );
    handle.dispose();
  });
}
