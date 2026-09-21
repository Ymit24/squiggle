import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/widgets/squiggle_pressable.dart';

void main() {
  testWidgets('reports interaction state and invokes onPressed', (
    tester,
  ) async {
    var presses = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: SquigglePressable(
          onPressed: () => presses++,
          builder: (context, state) =>
              Text('${state.isHovered}:${state.isFocused}:${state.isEnabled}'),
        ),
      ),
    );
    expect(find.text('false:false:true'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();

    expect(find.text('false:true:true'), findsOneWidget);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(gesture.removePointer);
    await gesture.addPointer();
    await gesture.moveTo(tester.getCenter(find.byType(SquigglePressable)));
    await tester.pump();

    expect(find.text('true:true:true'), findsOneWidget);

    await tester.tap(find.byType(SquigglePressable));
    expect(presses, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(presses, 2);
  });

  testWidgets('reports disabled state and ignores taps', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SquigglePressable(
          onPressed: null,
          builder: (context, state) => Text('${state.isEnabled}'),
        ),
      ),
    );

    expect(find.text('false'), findsOneWidget);
    await tester.tap(find.byType(SquigglePressable));
  });
}
