import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// Applies one saved side. Structural replay detaches outgoing subtrees first
/// so grouping/ungrouping can reuse descendant IDs without index collisions.
void applyDocumentState(
  NodeContainer container, {
  required Map<NodeId, data.Node?> states,
  required List<NodeId>? order,
}) {
  if (order == null) {
    _restoreInPlace(container, states);
    return;
  }
  final restored = <NodeId, Node>{
    for (final entry in states.entries)
      if (entry.value != null) entry.key: Node.fromDataModel(entry.value!),
  };
  container.removeAll(states.keys);
  for (final node in restored.values) {
    container.insert(node);
  }
  container.reorder(order);
}

void _restoreInPlace(NodeContainer container, Map<NodeId, data.Node?> states) {
  for (final entry in states.entries) {
    if (entry.value != null) {
      container.childById(entry.key)!.restoreFromDataModel(entry.value!);
    }
  }
}
