import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// Whether the selection contains at least two direct siblings.
bool canGroupSelectedNodes(EditorContext context) {
  final nodes = context.selection.selectedNodeIds
      .map(context.document.requireNodeById)
      .toList();
  if (nodes.length < 2) return false;
  final container = nodes.first.parent;
  return container != null &&
      nodes.every((node) => identical(node.parent, container));
}

List<Group> _selectedGroups(EditorContext context) => context
    .selection
    .selectedNodeIds
    .map(context.document.requireNodeById)
    .whereType<Group>()
    .toList();

/// Non-group nodes in a mixed selection do not affect ungroup eligibility.
bool canUngroupSelectedNodes(EditorContext context) {
  final groups = _selectedGroups(context);
  if (groups.isEmpty) return false;
  final container = groups.first.parent;
  return container != null &&
      groups.every((group) => identical(group.parent, container));
}

void groupSelectedNodes(EditorContext context) {
  if (!canGroupSelectedNodes(context)) return;
  final selectedIds = context.selection.selectedNodeIds.toSet();
  final container = context.document.requireNodeById(selectedIds.first).parent!;
  final siblings = container.children.toList();
  final selectedNodes = siblings
      .where((node) => selectedIds.contains(node.id))
      .toList();
  final topmostSelectedIndex = siblings.lastIndexWhere(
    (node) => selectedIds.contains(node.id),
  );
  final insertionIndex = siblings
      .take(topmostSelectedIndex)
      .where((node) => !selectedIds.contains(node.id))
      .length;

  context.history.run('Group Selected Nodes', (transaction) {
    transaction.removeAll(selectedIds);
    final bounds = Node.localBoundsOfNodes(selectedNodes);

    for (final node in selectedNodes) {
      node.origin -= bounds.center;
    }
    final group = Group(
      children: selectedNodes.toList(),
      origin: bounds.center,
    );
    transaction.add(group, index: insertionIndex);
    context.selection.setSelection([group.id]);
  }, container: container);
}

void ungroupSelectedNodes(EditorContext context) {
  if (!canUngroupSelectedNodes(context)) return;
  final selectedNodes = _selectedGroups(context);
  final container = selectedNodes.first.parent!;
  final selectedIds = selectedNodes.map((group) => group.id).toSet();
  final originalOrder = container.children.toList();
  final newSelection = <NodeId>[];
  context.history.run('Ungroup Selected Nodes', (transaction) {
    transaction.removeAll(selectedIds);
    final replacementIds = <NodeId, List<NodeId>>{};
    for (final group in selectedNodes) {
      final children = group.children.toList();
      group.removeAll(children.map((child) => child.id));
      for (final child in children) {
        child.origin += group.origin;
        transaction.add(child);
      }
      replacementIds[group.id] = children.map((child) => child.id).toList();
      newSelection.addAll(children.map((child) => child.id));
    }
    transaction.reorder([
      for (final node in originalOrder)
        if (replacementIds[node.id] case final children?)
          ...children
        else
          node.id,
    ]);
  }, container: container);
  context.selection.setSelection(newSelection);
}
