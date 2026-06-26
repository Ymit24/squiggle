import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_layout.dart';

void main() {
  Document docWithRectangles(List<Offset> origins, {Size size = const Size(10, 10)}) {
    return Document.fromFeatures([
      for (final origin in origins)
        Feature(
          origin: origin,
          size: size,
          kind: const FeatureKindRectangle(),
        ),
    ]);
  }

  group('computeAlignmentOffsets', () {
    test('returns empty map for fewer than two features', () {
      final doc = docWithRectangles([Offset.zero]);
      final id = doc.features.first.id;

      expect(
        computeAlignmentOffsets(doc, [id], FeatureAlignment.left),
        isEmpty,
      );
    });

    test('aligns left edges to selection bounds', () {
      final doc = docWithRectangles([
        const Offset(0, 0),
        const Offset(30, 5),
        const Offset(10, 20),
      ]);
      final ids = doc.features.map((feature) => feature.id).toList();

      final offsets = computeAlignmentOffsets(
        doc,
        ids,
        FeatureAlignment.left,
      );

      expect(offsets[ids[0]], isNull);
      expect(offsets[ids[1]], const Offset(-30, 0));
      expect(offsets[ids[2]], const Offset(-10, 0));
    });

    test('aligns centers horizontally', () {
      final doc = docWithRectangles([
        const Offset(0, 0),
        const Offset(40, 0),
      ]);
      final ids = doc.features.map((feature) => feature.id).toList();

      final offsets = computeAlignmentOffsets(
        doc,
        ids,
        FeatureAlignment.centerHorizontal,
      );

      expect(offsets[ids[0]], const Offset(20, 0));
      expect(offsets[ids[1]], const Offset(-20, 0));
    });
  });

  group('computeDistributionOffsets', () {
    test('returns empty map for fewer than three features', () {
      final doc = docWithRectangles([
        Offset.zero,
        const Offset(20, 0),
      ]);
      final ids = doc.features.map((feature) => feature.id).toList();

      expect(
        computeDistributionOffsets(
          doc,
          ids,
          FeatureDistribution.horizontal,
        ),
        isEmpty,
      );
    });

    test('distributes features with equal spacing horizontally', () {
      final doc = docWithRectangles([
        const Offset(0, 0),
        const Offset(30, 0),
        const Offset(100, 0),
      ]);
      final ids = doc.features.map((feature) => feature.id).toList();

      final offsets = computeDistributionOffsets(
        doc,
        ids,
        FeatureDistribution.horizontal,
      );

      expect(offsets[ids[0]], isNull);
      expect(offsets[ids[1]], const Offset(20, 0));
      expect(offsets[ids[2]], isNull);
    });

    test('distributes features with equal spacing vertically', () {
      final doc = docWithRectangles([
        const Offset(0, 0),
        const Offset(0, 30),
        const Offset(0, 100),
      ]);
      final ids = doc.features.map((feature) => feature.id).toList();

      final offsets = computeDistributionOffsets(
        doc,
        ids,
        FeatureDistribution.vertical,
      );

      expect(offsets[ids[0]], isNull);
      expect(offsets[ids[1]], const Offset(0, 20));
      expect(offsets[ids[2]], isNull);
    });
  });
}
