import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/services/feature_clipboard.dart';

void main() {
  group('repositionFeaturesToCenter', () {
    test('centers a single feature on the target', () {
      final feature = Feature(
        origin: const Offset(100, 50),
        size: const Size(200, 100),
        kind: const FeatureKindRectangle(),
      );

      final repositioned = repositionFeaturesToCenter(
        [feature],
        const Offset(500, 400),
      );

      expect(repositioned, hasLength(1));
      expect(repositioned.first.bounds().center, const Offset(500, 400));
    });

    test('preserves relative offsets for multiple features', () {
      final first = Feature(
        origin: const Offset(0, 0),
        size: const Size(100, 100),
        kind: const FeatureKindRectangle(),
      );
      final second = Feature(
        origin: const Offset(120, 40),
        size: const Size(50, 50),
        kind: const FeatureKindCircle(),
      );

      final repositioned = repositionFeaturesToCenter(
        [first, second],
        const Offset(300, 300),
      );

      expect(
        boundsOfFeatures(repositioned).center,
        const Offset(300, 300),
      );
      expect(
        repositioned[1].origin - repositioned[0].origin,
        second.origin - first.origin,
      );
    });
  });
}
