import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/node_id.dart';

enum LayerOrder { backward, forward, back, front }

List<NodeId>? _newOrder(EditorContext context, LayerOrder action) {
  final selectedIds = context.selection.selectedNodeIds.toSet();
  if (selectedIds.isEmpty) return null;
  final nodes = selectedIds.map(context.document.nodeById).toList();
  if (nodes.any((node) => node == null)) return null;
  final container = nodes.first!.parent;
  if (container == null ||
      nodes.any((node) => !identical(node!.parent, container))) {
    return null;
  }

  final order = container.children.map((node) => node.id).toList();
  switch (action) {
    case LayerOrder.backward:
      for (var i = 1; i < order.length; i++) {
        if (selectedIds.contains(order[i]) &&
            !selectedIds.contains(order[i - 1])) {
          final id = order[i];
          order[i] = order[i - 1];
          order[i - 1] = id;
        }
      }
    case LayerOrder.forward:
      for (var i = order.length - 2; i >= 0; i--) {
        if (selectedIds.contains(order[i]) &&
            !selectedIds.contains(order[i + 1])) {
          final id = order[i];
          order[i] = order[i + 1];
          order[i + 1] = id;
        }
      }
    case LayerOrder.back:
      order
        ..removeWhere(selectedIds.contains)
        ..insertAll(
          0,
          container.children.map((node) => node.id).where(selectedIds.contains),
        );
    case LayerOrder.front:
      order
        ..removeWhere(selectedIds.contains)
        ..addAll(
          container.children.map((node) => node.id).where(selectedIds.contains),
        );
  }
  if (order.asMap().entries.every(
    (entry) => entry.value == container.children[entry.key].id,
  )) {
    return null;
  }
  return order;
}

bool canReorderSelectedNodes(EditorContext context, LayerOrder action) =>
    _newOrder(context, action) != null;

void reorderSelectedNodes(EditorContext context, LayerOrder action) {
  final order = _newOrder(context, action);
  if (order == null) return;
  final first = context.document.requireNodeById(
    context.selection.selectedNodeIds.first,
  );
  context.history.run('Reorder selection', (transaction) {
    transaction.reorder(order);
  }, container: first.parent);
}
