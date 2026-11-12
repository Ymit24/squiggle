import 'dart:ui';

import 'package:collection/collection.dart';

import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// Attaches one end of a feature to another node. The end floats: it sits
/// where the line toward the target's center crosses the target's outline.
class NodeBinding {
  const NodeBinding(this.targetId);

  factory NodeBinding.fromDataModel(Map<String, dynamic> raw) =>
      NodeBinding(NodeId.newId(raw['target'] as int));

  final NodeId targetId;

  Map<String, dynamic> toDataModel() => {'target': targetId.value};

  Node? target(Document document) => document.nodeById(targetId);

  /// This binding retargeted through [ids], or null when its target is absent.
  NodeBinding? remapped(Map<NodeId, NodeId> ids) => switch (ids[targetId]) {
    final id? => NodeBinding(id),
    null => null,
  };
}

/// Whether a feature end may bind to [target]. Binding features cannot be
/// targets, and neither can [line]'s ancestors, whose bounds include the line.
bool canBindTo(Node target, {Feature? line}) {
  if (target case Feature(kind: BindingCapable())) return false;
  return line == null || !isWithin(line, {target.id});
}

/// Whether [node] or one of its ancestors has an id in [ids].
bool isWithin(Node node, Set<NodeId> ids) {
  Node? current = node;
  while (current != null) {
    if (ids.contains(current.id)) return true;
    final parent = current.parent;
    current = parent is Node ? parent as Node : null;
  }
  return false;
}

/// Lines whose ends are being resolved. Resolving reads target bounds, and a
/// group's bounds include its lines, so lines bound across groups can lead
/// back to a line already being resolved: that is a cycle.
final Set<Feature> _resolving = {};

/// [line]'s [points] (in its parent space) with the ends held by [start] and
/// [end] moved onto their targets. Missing targets and binding cycles leave
/// the stored points in place.
List<Offset> resolveBindings(
  Feature line,
  List<Offset> points, {
  NodeBinding? start,
  NodeBinding? end,
}) {
  final document = line.document;
  if (points.length < 2 || document == null || (start ?? end) == null) {
    return points;
  }
  if (!_resolving.add(line)) return points;
  try {
    final shift = line.parent!.globalOrigin;
    final resolved = resolveBoundEnds(
      [for (final point in points) point + shift],
      start: start?.target(document),
      end: end?.target(document),
    );
    return [for (final point in resolved) point - shift];
  } finally {
    _resolving.remove(line);
  }
}

/// Moves the ends of [points] (global space) onto [start]'s and [end]'s
/// outlines. Ends of a two-point line bound at both ends aim at the other
/// target's center, so neither end depends on the other's resolved position.
List<Offset> resolveBoundEnds(List<Offset> points, {Node? start, Node? end}) {
  final resolved = List.of(points);
  final isDirect = points.length == 2;
  if (start != null) {
    final aim = isDirect && end != null ? end.globalBounds().center : points[1];
    resolved.first = start.outlinePointToward(aim);
  }
  if (end != null) {
    final aim = isDirect && start != null
        ? start.globalBounds().center
        : points[points.length - 2];
    resolved.last = end.outlinePointToward(aim);
  }
  return resolved;
}

/// Fixes up [copies] of [sources] once the copies have ids: bindings between
/// copied nodes follow the copies, and other bindings are dropped with their
/// ends left where they were drawn.
void rebindCopies(List<Node> sources, List<Node> copies) {
  // Copies mirror their sources' structure, so their subtrees line up.
  final pairs = IterableZip([
    sources.expand((node) => node.subtree),
    copies.expand((node) => node.subtree),
  ]).map((pair) => (pair[0], pair[1])).toList();
  final ids = {for (final (source, copy) in pairs) source.id: copy.id};
  for (final pair in pairs) {
    if (pair case (
      Feature source,
      Feature(kind: BindingCapable kind) && final copy,
    )) {
      kind.rebindCopy(copy, source, ids);
    }
  }
}
