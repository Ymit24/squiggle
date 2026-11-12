import 'dart:ui';

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
  final pairs = <(Node, Node)>[];
  for (var i = 0; i < sources.length; i++) {
    _collectPairs(sources[i], copies[i], pairs);
  }
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

void _collectPairs(Node source, Node copy, List<(Node, Node)> pairs) {
  pairs.add((source, copy));
  if (source is! NodeContainer || copy is! NodeContainer) return;
  final sourceChildren = (source as NodeContainer).children;
  final copyChildren = (copy as NodeContainer).children;
  for (var i = 0; i < sourceChildren.length; i++) {
    _collectPairs(sourceChildren[i], copyChildren[i], pairs);
  }
}
