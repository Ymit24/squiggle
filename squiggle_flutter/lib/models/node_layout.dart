import 'dart:ui';

import 'package:squiggle_flutter/models/node.dart';

enum NodeAlignment {
  left,
  centerHorizontal,
  right,
  top,
  centerVertical,
  bottom,
}

enum NodeDistribution { horizontal, vertical }

/// Aligns [nodes] within their selection bounds.
void alignNodes(List<Node> nodes, NodeAlignment alignment) {
  if (nodes.length < 2) return;

  final union = Node.localBoundsOfNodes(nodes);

  for (final node in nodes) {
    final bounds = node.localBounds();
    final delta = switch (alignment) {
      NodeAlignment.left => Offset(union.left - bounds.left, 0),
      NodeAlignment.right => Offset(union.right - bounds.right, 0),
      NodeAlignment.top => Offset(0, union.top - bounds.top),
      NodeAlignment.bottom => Offset(0, union.bottom - bounds.bottom),
      NodeAlignment.centerHorizontal => Offset(
        union.center.dx - bounds.center.dx,
        0,
      ),
      NodeAlignment.centerVertical => Offset(
        0,
        union.center.dy - bounds.center.dy,
      ),
    };
    node.origin += delta;
  }
}

/// Evenly distributes [nodes] between the extremes.
void distributeNodes(List<Node> nodes, NodeDistribution distribution) {
  if (nodes.length < 3) return;

  final entries = nodes
      .map((node) => (node: node, bounds: node.localBounds()))
      .toList();

  switch (distribution) {
    case NodeDistribution.horizontal:
      entries.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
      _distributeAlongAxis(entries, horizontal: true);
    case NodeDistribution.vertical:
      entries.sort((a, b) => a.bounds.top.compareTo(b.bounds.top));
      _distributeAlongAxis(entries, horizontal: false);
  }
}

void _distributeAlongAxis(
  List<({Node node, Rect bounds})> sorted, {
  required bool horizontal,
}) {
  final first = sorted.first.bounds;
  final last = sorted.last.bounds;

  final totalObjectSize = sorted.fold<double>(
    0,
    (sum, entry) =>
        sum + (horizontal ? entry.bounds.width : entry.bounds.height),
  );

  final span = horizontal ? last.right - first.left : last.bottom - first.top;
  final gap = (span - totalObjectSize) / (sorted.length - 1);

  var current = horizontal ? first.left : first.top;

  for (final entry in sorted) {
    final bounds = entry.bounds;
    final delta = horizontal
        ? Offset(current - bounds.left, 0)
        : Offset(0, current - bounds.top);

    entry.node.origin += delta;

    current += (horizontal ? bounds.width : bounds.height) + gap;
  }
}
