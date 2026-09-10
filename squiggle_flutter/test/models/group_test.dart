import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';

void main() {
  group('Group.resize', () {
    test('scales child sizes and spacing from offset bounds', () {
      final first = rectangle(const Rect.fromLTWH(-10, 20, 20, 30));
      final second = rectangle(const Rect.fromLTWH(30, 60, 10, 10));
      final group = Group(
        origin: const Offset(100, 200),
        children: [first, second],
      );

      group.resize(const Rect.fromLTWH(300, 400, 100, 150));

      expect(group.localBounds(), const Rect.fromLTWH(300, 400, 100, 150));
      expect(first.globalBounds(), const Rect.fromLTWH(300, 400, 40, 90));
      expect(second.globalBounds(), const Rect.fromLTWH(380, 520, 20, 30));
      expect(first.parent, same(group));
    });

    test('resizes nested groups in their parent coordinates', () {
      final feature = rectangle(const Rect.fromLTWH(10, 20, 30, 40));
      final nested = Group(origin: const Offset(50, 60), children: [feature]);
      final group = Group(origin: const Offset(100, 200), children: [nested]);

      group.resize(const Rect.fromLTWH(300, 400, 60, 120));

      expect(group.localBounds(), const Rect.fromLTWH(300, 400, 60, 120));
      expect(feature.globalBounds(), const Rect.fromLTWH(300, 400, 60, 120));
      expect(feature.parent, same(nested));
      expect(nested.parent, same(group));
    });

    test('delegates polyline geometry resizing', () {
      final feature = Feature(
        origin: const Offset(10, 20),
        size: const Size(30, 40),
        kind: const FeatureKindPolyline([
          Offset.zero,
          Offset(30, 40),
        ], strokeWidth: 0),
      );
      final group = Group(origin: const Offset(100, 200), children: [feature]);

      group.resize(const Rect.fromLTWH(300, 400, 60, 120));

      expect(feature.globalBounds(), const Rect.fromLTWH(300, 400, 60, 120));
      expect((feature.kind as FeatureKindPolyline).localPoints, [
        Offset.zero,
        const Offset(60, 120),
      ]);
    });

    test('keeps degenerate dimensions finite', () {
      for (final size in [const Size(0, 20), const Size(20, 0), Size.zero]) {
        final feature = rectangle(Offset(10, 20) & size);
        final group = Group(
          origin: const Offset(100, 200),
          children: [feature],
        );

        group.resize(const Rect.fromLTWH(300, 400, 60, 120));

        expect(feature.globalBounds().topLeft, const Offset(300, 400));
        expect(
          feature.size,
          Size(size.width == 0 ? 0 : 60, size.height == 0 ? 0 : 120),
        );
      }
    });

    test('moves empty groups without introducing nonfinite bounds', () {
      final group = Group(origin: const Offset(100, 200), children: []);

      group.resize(const Rect.fromLTWH(300, 400, 60, 120));

      expect(group.localBounds(), const Rect.fromLTWH(300, 400, 0, 0));
    });
  });
}

Feature rectangle(Rect bounds) => Feature(
  origin: bounds.topLeft,
  size: bounds.size,
  kind: const FeatureKindRectangle(),
);
