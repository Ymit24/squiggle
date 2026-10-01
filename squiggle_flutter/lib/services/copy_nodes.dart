import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// Copies disjoint node trees, preserving geometry and internal connections.
/// Sources must have unique IDs. Clipboard snapshots retain IDs; insertion
/// allocates fresh ones. Neither operation changes the original nodes.
List<Node> copyNodes(
  List<Node> originals, {
  required NodeId Function(NodeId originalId) allocateId,
}) {
  final copiedIds = <NodeId, NodeId>{
    for (final root in originals)
      for (final node in _walk(root)) node.id: allocateId(node.id),
  };

  Node copyNode(Node original) {
    if (original is Group) {
      return Group(
        id: copiedIds[original.id]!,
        origin: original.origin,
        children: original.children.map(copyNode).toList(),
      );
    }

    final feature = original as Feature;
    final copy = feature.copyWith(id: copiedIds[feature.id]!);
    if (feature.kind case BindingSourceCapable source) {
      source.prepareCopy(feature, copy, copiedIds);
    }
    return copy;
  }

  return originals.map(copyNode).toList();
}

Iterable<Node> _walk(Node node) sync* {
  yield node;
  if (node is Group) {
    for (final child in node.children) {
      yield* _walk(child);
    }
  }
}
