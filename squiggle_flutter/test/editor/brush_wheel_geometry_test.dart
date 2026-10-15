import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/brush_wheel/brush_wheel_geometry.dart';

void main() {
  const ring = BrushWheelGeometry.slotRadius;

  test('slots start at 12 o\'clock and run clockwise', () {
    expect(BrushWheelGeometry.slotAt(const Offset(0, -ring), 4), 0);
    expect(BrushWheelGeometry.slotAt(const Offset(ring, 0), 4), 1);
    expect(BrushWheelGeometry.slotAt(const Offset(0, ring), 4), 2);
    expect(BrushWheelGeometry.slotAt(const Offset(-ring, 0), 4), 3);
    for (var index = 0; index < 7; index++) {
      expect(
        BrushWheelGeometry.slotAt(BrushWheelGeometry.slotCenter(index, 7), 7),
        index,
      );
    }
  });

  test('a slot owns its whole slice, not just the tile', () {
    // 40° clockwise from the top is still inside slot 0's 90° slice.
    expect(BrushWheelGeometry.slotAt(const Offset(40, -50), 4), 0);
    expect(BrushWheelGeometry.slotAt(const Offset(50, -40), 4), 1);
  });

  test('the dead zone and outside the disc select nothing', () {
    expect(BrushWheelGeometry.slotAt(Offset.zero, 7), isNull);
    expect(BrushWheelGeometry.slotAt(const Offset(0, -20), 7), isNull);
    expect(BrushWheelGeometry.slotAt(const Offset(0, -130), 7), isNull);
    expect(BrushWheelGeometry.slotAt(const Offset(0, -ring), 0), isNull);
  });

  test('clampCenter keeps the wheel and label on screen', () {
    const viewport = Size(800, 600);
    expect(
      BrushWheelGeometry.clampCenter(const Offset(400, 300), viewport),
      const Offset(400, 300),
    );
    final corner = BrushWheelGeometry.clampCenter(Offset.zero, viewport);
    expect(corner.dx - BrushWheelGeometry.outerRadius, greaterThanOrEqualTo(0));
    expect(corner.dy - BrushWheelGeometry.outerRadius, greaterThanOrEqualTo(0));
    final bottom = BrushWheelGeometry.clampCenter(
      const Offset(400, 600),
      viewport,
    );
    final wheelBottom =
        bottom.dy -
        BrushWheelGeometry.outerRadius +
        BrushWheelGeometry.size.height;
    expect(wheelBottom, lessThanOrEqualTo(600));
  });
}
