import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';

void main() {
  group('centerRectFromPoints', () {
    test('expands symmetrically from center', () {
      expect(
        centerRectFromPoints(const Offset(50, 50), const Offset(100, 80)),
        const Rect.fromLTWH(0, 20, 100, 60),
      );
    });

    test('works when dragging to upper-left quadrant', () {
      expect(
        centerRectFromPoints(const Offset(50, 50), const Offset(20, 30)),
        const Rect.fromLTWH(20, 30, 60, 40),
      );
    });
  });

  group('squareCenterRectFromPoints', () {
    test('uses larger axis for side length', () {
      expect(
        squareCenterRectFromPoints(const Offset(50, 50), const Offset(100, 80)),
        const Rect.fromLTWH(0, 0, 100, 100),
      );
    });
  });

  group('squareRectFromPoints', () {
    test('uses larger axis for side length', () {
      expect(
        squareRectFromPoints(const Offset(0, 0), const Offset(100, 50)),
        const Rect.fromLTWH(0, 0, 100, 100),
      );
    });

    test('preserves drag direction', () {
      expect(
        squareRectFromPoints(const Offset(100, 100), const Offset(0, 50)),
        const Rect.fromLTWH(0, 0, 100, 100),
      );
    });
  });

  group('snapPointTo45DegreeAngle', () {
    test('snaps near-horizontal to horizontal', () {
      const point = Offset(100, 10);
      final snapped = snapPointTo45DegreeAngle(Offset.zero, point);
      expect(snapped.dy, closeTo(0, 0.001));
      expect(snapped.distance, closeTo(point.distance, 0.001));
    });

    test('snaps near-diagonal to 45 degrees', () {
      const point = Offset(100, 90);
      final snapped = snapPointTo45DegreeAngle(Offset.zero, point);
      expect(snapped.dx, closeTo(snapped.dy, 0.001));
      expect(snapped.distance, closeTo(point.distance, 0.001));
    });

    test('preserves distance from origin', () {
      const point = Offset(70, 70);
      final snapped = snapPointTo45DegreeAngle(Offset.zero, point);
      expect(snapped.distance, closeTo(point.distance, 0.001));
    });
  });

  group('constrainMoveToAxis', () {
    test('locks to horizontal when dx dominates', () {
      expect(
        constrainMoveToAxis(const Offset(0, 0), const Offset(50, 10)),
        const Offset(50, 0),
      );
    });

    test('locks to vertical when dy dominates', () {
      expect(
        constrainMoveToAxis(const Offset(0, 0), const Offset(10, 50)),
        const Offset(0, 50),
      );
    });
  });

  group('rectFromAnchorWithAspectRatio', () {
    test('locks corner resize to initial ratio', () {
      final rect = rectFromAnchorWithAspectRatio(
        const Offset(0, 0),
        const Offset(200, 100),
        2.0,
      );
      expect(rect.width, closeTo(200, 0.001));
      expect(rect.height, closeTo(100, 0.001));
    });
  });

  group('edgeResizeWithAspectRatio', () {
    test('expands width symmetrically when resizing bottom edge', () {
      final rect = edgeResizeWithAspectRatio(
        const Rect.fromLTWH(0, 0, 100, 100),
        const Offset(50, 150),
        resizeTop: false,
        resizeBottom: true,
        resizeLeft: false,
        resizeRight: false,
        aspectRatio: 1.0,
      );
      expect(rect.width, closeTo(150, 0.001));
      expect(rect.height, closeTo(150, 0.001));
      expect(rect.top, closeTo(0, 0.001));
    });
  });

  group('symmetricRectWithAspectRatio', () {
    test('locks symmetric corner resize', () {
      final rect = symmetricRectWithAspectRatio(
        const Offset(50, 50),
        const Offset(150, 120),
        1.0,
        resizeHorizontal: true,
        resizeVertical: true,
      );
      expect(rect.width, closeTo(rect.height, 0.001));
    });
  });
}
