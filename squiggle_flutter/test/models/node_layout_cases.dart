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

  group('alignNodes', () {
    test('does nothing for fewer than two features', () {
      final doc = docWithRectangles([Offset.zero]);
      final node = doc.nodes.first;

      alignNodes([node], NodeAlignment.left);

      expect(node.origin, Offset.zero);
    });

    test('aligns left edges to selection bounds', () {
      final doc = docWithRectangles([
        const Offset(0, 0),
        const Offset(30, 5),
        const Offset(10, 20),
      ]);
      final nodes = doc.nodes;

      alignNodes(nodes, NodeAlignment.left);

      expect(nodes[0].origin, const Offset(0, 0));
      expect(nodes[1].origin, const Offset(0, 5));
      expect(nodes[2].origin, const Offset(0, 20));
    });

    test('aligns centers horizontally', () {
      final doc = docWithRectangles([const Offset(0, 0), const Offset(40, 0)]);
      final nodes = doc.nodes;

      alignNodes(nodes, NodeAlignment.centerHorizontal);

      expect(nodes[0].origin, const Offset(20, 0));
      expect(nodes[1].origin, const Offset(20, 0));
    });
  });

  group('distributeNodes', () {
    test('does nothing for fewer than three features', () {
      final doc = docWithRectangles([Offset.zero, const Offset(20, 0)]);
      final nodes = doc.nodes;

      distributeNodes(nodes, NodeDistribution.horizontal);

      expect(nodes.map((node) => node.origin), [
        Offset.zero,
        const Offset(20, 0),
      ]);
    });

    test('distributes features with equal spacing horizontally', () {
      final doc = docWithRectangles([
        const Offset(0, 0),
        const Offset(30, 0),
        const Offset(100, 0),
      ]);
      final nodes = doc.nodes;

      distributeNodes(nodes, NodeDistribution.horizontal);

      expect(nodes[0].origin, const Offset(0, 0));
      expect(nodes[1].origin, const Offset(50, 0));
      expect(nodes[2].origin, const Offset(100, 0));
    });

    test('distributes features with equal spacing vertically', () {
      final doc = docWithRectangles([
        const Offset(0, 0),
        const Offset(0, 30),
        const Offset(0, 100),
      ]);
      final nodes = doc.nodes;

      distributeNodes(nodes, NodeDistribution.vertical);

      expect(nodes[0].origin, const Offset(0, 0));
      expect(nodes[1].origin, const Offset(0, 50));
      expect(nodes[2].origin, const Offset(0, 100));
    });
  });
}
