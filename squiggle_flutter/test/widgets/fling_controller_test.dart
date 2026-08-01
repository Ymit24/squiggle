import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/widgets/fling_controller.dart';

void main() {
  testWidgets('fling reports pan deltas and stops when the simulation ends', (
    tester,
  ) async {
    final deltas = <Offset>[];
    final fling = FlingController(vsync: TestVSync(), onPan: deltas.add);

    fling.fling(const Offset(1000, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(fling.isActive, isTrue);
    expect(deltas, isNotEmpty);
    expect(deltas.first.dx, greaterThan(0));

    await tester.pumpAndSettle();

    expect(fling.isActive, isFalse);
    final totalDx = deltas.fold<Offset>(Offset.zero, (sum, d) => sum + d).dx;
    expect(totalDx, greaterThan(0));

    fling.dispose();
  });

  testWidgets('fling restarts with a new velocity', (tester) async {
    final deltas = <Offset>[];
    final fling = FlingController(vsync: TestVSync(), onPan: deltas.add);

    fling.fling(const Offset(1000, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final firstFrame = deltas.length;
    expect(firstFrame, greaterThan(0));

    fling.fling(const Offset(-2000, 500));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(deltas.length, firstFrame + 1);
    expect(deltas.last.dx, lessThan(0));
    expect(deltas.last.dy, greaterThan(0));

    fling.stop();
    expect(fling.isActive, isFalse);
    fling.dispose();
  });

  testWidgets('stop halts a running fling', (tester) async {
    final deltas = <Offset>[];
    final fling = FlingController(vsync: TestVSync(), onPan: deltas.add);

    fling.fling(const Offset(1000, 0));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(fling.isActive, isTrue);

    fling.stop();
    expect(fling.isActive, isFalse);

    final lengthAfterStop = deltas.length;
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(deltas.length, lengthAfterStop);

    fling.dispose();
  });
}
