import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node_layout.dart';

void main() {
  Document docWithRectangles(
    List<Offset> origins, {
    Size size = const Size(10, 10),
  }) {
    return Document.fromFeatures([
      for (final origin in origins)
        Feature(origin: origin, size: size, kind: FeatureKindRectangle()),
    ]);
  }

  group('computeAlignmentOffsets', () {
    test('returns empty map for fewer than two features', () {
      final doc = docWithRectangles([Offset.zero]);
      final node = doc.nodes.first;

      expect(computeAlignmentOffsets(doc, [node], NodeAlignment.left), isEmpty);
    });

    test('aligns left edges to selection bounds', () {
      final doc = docWithRectangles([
        const Offset(0, 0),
        const Offset(30, 5),
        const Offset(10, 20),
      ]);
      final nodes = doc.nodes;

      final offsets = computeAlignmentOffsets(doc, nodes, NodeAlignment.left);

      expect(offsets[nodes[0].id], isNull);
      expect(offsets[nodes[1].id], const Offset(-30, 0));
      expect(offsets[nodes[2].id], const Offset(-10, 0));
    });

    test('aligns centers horizontally', () {
      final doc = docWithRectangles([const Offset(0, 0), const Offset(40, 0)]);
      final nodes = doc.nodes;

      final offsets = computeAlignmentOffsets(
        doc,
        nodes,
        NodeAlignment.centerHorizontal,
      );

      expect(offsets[nodes[0].id], const Offset(20, 0));
      expect(offsets[nodes[1].id], const Offset(-20, 0));
    });
  });

  group('computeDistributionOffsets', () {
    test('returns empty map for fewer than three features', () {
      final doc = docWithRectangles([Offset.zero, const Offset(20, 0)]);
      final nodes = doc.nodes;

      expect(
        computeDistributionOffsets(doc, nodes, NodeDistribution.horizontal),
        isEmpty,
      );
    });

    test('distributes features with equal spacing horizontally', () {
      final doc = docWithRectangles([
        const Offset(0, 0),
        const Offset(30, 0),
        const Offset(100, 0),
      ]);
      final nodes = doc.nodes;

      final offsets = computeDistributionOffsets(
        doc,
        nodes,
        NodeDistribution.horizontal,
      );

      expect(offsets[nodes[0].id], isNull);
      expect(offsets[nodes[1].id], const Offset(20, 0));
      expect(offsets[nodes[2].id], isNull);
    });

    test('distributes features with equal spacing vertically', () {
      final doc = docWithRectangles([
        const Offset(0, 0),
        const Offset(0, 30),
        const Offset(0, 100),
      ]);
      final nodes = doc.nodes;

      final offsets = computeDistributionOffsets(
        doc,
        nodes,
        NodeDistribution.vertical,
      );

      expect(offsets[nodes[0].id], isNull);
      expect(offsets[nodes[1].id], const Offset(0, 20));
      expect(offsets[nodes[2].id], isNull);
    });
  });
}
