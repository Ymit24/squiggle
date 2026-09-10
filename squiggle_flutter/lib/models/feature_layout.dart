import 'dart:ui';

import 'package:squiggle_flutter/models/node.dart';

import 'document.dart';

import 'node_id.dart';

enum FeatureAlignment {
  left,
  centerHorizontal,
  right,
  top,
  centerVertical,
  bottom,
}

enum FeatureDistribution { horizontal, vertical }

/// Computes origin deltas to align [ids] within their selection bounds.
Map<NodeId, Offset> computeAlignmentOffsets(
  Document document,
  List<NodeId> ids,
  FeatureAlignment alignment,
) {
  if (ids.length < 2) return const {};

  final nodes = ids.map(document.nodeById).whereType<Node>().toList();
  if (nodes.length < 2) return const {};

  var union = Node.localBoundsOfNodes(nodes);

  final offsets = <NodeId, Offset>{};
  for (final feature in nodes) {
    final bounds = feature.localBounds();
    final delta = switch (alignment) {
      FeatureAlignment.left => Offset(union.left - bounds.left, 0),
      FeatureAlignment.right => Offset(union.right - bounds.right, 0),
      FeatureAlignment.top => Offset(0, union.top - bounds.top),
      FeatureAlignment.bottom => Offset(0, union.bottom - bounds.bottom),
      FeatureAlignment.centerHorizontal => Offset(
        union.center.dx - bounds.center.dx,
        0,
      ),
      FeatureAlignment.centerVertical => Offset(
        0,
        union.center.dy - bounds.center.dy,
      ),
    };
    if (delta != Offset.zero) {
      offsets[feature.id] = delta;
    }
  }
  return offsets;
}

/// Computes origin deltas to evenly distribute [ids] between the extremes.
Map<NodeId, Offset> computeDistributionOffsets(
  Document document,
  List<NodeId> ids,
  FeatureDistribution distribution,
) {
  if (ids.length < 3) return const {};

  final entries = ids
      .map(document.nodeById)
      .whereType<Node>()
      .map((feature) => (node: feature, bounds: feature.localBounds()))
      .toList();
  if (entries.length < 3) return const {};

  switch (distribution) {
    case FeatureDistribution.horizontal:
      entries.sort((a, b) => a.bounds.left.compareTo(b.bounds.left));
      return _distributeAlongAxis(entries, horizontal: true);
    case FeatureDistribution.vertical:
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
