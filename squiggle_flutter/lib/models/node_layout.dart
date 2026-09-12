import 'dart:ui';

import 'package:squiggle_flutter/models/node.dart';

import 'package:squiggle_flutter/models/document.dart';

import 'package:squiggle_flutter/models/node_id.dart';

enum NodeAlignment {
  left,
  centerHorizontal,
  right,
  top,
  centerVertical,
  bottom,
}

enum NodeDistribution { horizontal, vertical }

/// Computes origin deltas to align [ids] within their selection bounds.
Map<NodeId, Offset> computeAlignmentOffsets(
  Document document,
  List<NodeId> ids,
  NodeAlignment alignment,
) {
  if (ids.length < 2) return const {};

  final nodes = ids.map(document.requireNodeById).toList();

  var union = Node.localBoundsOfNodes(nodes);

  final offsets = <NodeId, Offset>{};
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
    if (delta != Offset.zero) {
      offsets[node.id] = delta;
    }
  }
  return offsets;
}

/// Computes origin deltas to evenly distribute [ids] between the extremes.
Map<NodeId, Offset> computeDistributionOffsets(
  Document document,
  List<NodeId> ids,
  NodeDistribution distribution,
) {
  if (ids.length < 3) return const {};

  final entries = ids
      .map(document.requireNodeById)
      .map((node) => (node: node, bounds: node.localBounds()))
      .toList();

  switch (distribution) {
    case NodeDistribution.horizontal:
      entries.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
      return _distributeAlongAxis(entries, horizontal: true);
    case NodeDistribution.vertical:
      entries.sort((a, b) => a.bounds.top.compareTo(b.bounds.top));
      return _distributeAlongAxis(entries, horizontal: false);
  }
}

Map<NodeId, Offset> _distributeAlongAxis(
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

  final offsets = <NodeId, Offset>{};
  var current = horizontal ? first.left : first.top;

  for (final entry in sorted) {
    final bounds = entry.bounds;
    final delta = horizontal
        ? Offset(current - bounds.left, 0)
        : Offset(0, current - bounds.top);

    if (delta != Offset.zero) {
      offsets[entry.node.id] = delta;
    }

    current += (horizontal ? bounds.width : bounds.height) + gap;
  }

  return offsets;
}
