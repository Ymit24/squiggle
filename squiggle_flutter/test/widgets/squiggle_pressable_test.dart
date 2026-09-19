import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_pressable.dart';

void main() {
  testWidgets('activates with pointer and keyboard', (tester) async {
    var activations = 0;
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SquigglePressable(
            focusNode: focusNode,
            onPressed: () => activations += 1,
            builder: (context, state) =>
                const SizedBox(width: 80, height: 40, child: Text('Action')),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Action'));
    expect(activations, 1);

    focusNode.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(activations, 2);
  });

  testWidgets('reports hover and disabled states to its builder', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SquigglePressable(
            onPressed: null,
            builder: (context, state) => SizedBox(
              width: 80,
              height: 40,
              child: Text('${state.hovered}:${state.enabled}'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('false:false'), findsOneWidget);

    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.byType(SquigglePressable)));
    await tester.pump();

    expect(find.text('true:false'), findsOneWidget);
  });
}
