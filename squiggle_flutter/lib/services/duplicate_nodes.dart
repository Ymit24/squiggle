import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/history/edit.dart';
import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// Copies nodes into the supplied edit, applying [offset] in parent coordinates.
List<Node> duplicateNodes({
  required List<Node> nodes,
  required Transaction transaction,
  required SelectionModel selection,
  Offset offset = Offset.zero,
}) {
  final clones = nodes
      .map((node) => node.copyWith(id: noId, origin: node.origin + offset))
      .toList();
  for (final clone in clones) {
    transaction.add(clone);
  }
  selection.setSelection(clones.map((node) => node.id));
  return clones;
}

List<Node> _duplicableSelection(EditorContext context) {
  final ids = context.selection.selectedNodeIds.toSet();
  if (ids.isEmpty) return [];
  final nodes = ids.map(context.document.nodeById).toList();
  if (nodes.any((node) => node == null)) return [];
  final parent = nodes.first!.parent;
  if (parent == null || nodes.any((node) => !identical(node!.parent, parent))) {
    return [];
  }
  // Use paint order rather than the order in which nodes were selected.
  return parent.children.where((node) => ids.contains(node.id)).toList();
}

bool canDuplicateSelectedNodes(EditorContext context) =>
    _duplicableSelection(context).isNotEmpty;

/// Cancels the current interaction and duplicates sibling nodes in one edit.
/// Copies are offset 64 canvas units right and down.
bool duplicateSelectedNodes(EditorContext context) {
  if (!canDuplicateSelectedNodes(context)) return false;
  context.cancelInteraction();
  // Cancellation can restore group children or remove transient drag copies.
  final nodes = _duplicableSelection(context);
  if (nodes.isEmpty) return false;
  context.history.run('Duplicate selection', (transaction) {
    duplicateNodes(
      nodes: nodes,
      transaction: transaction,
      selection: context.selection,
      offset: const Offset(64, 64),
    );
  }, container: nodes.first.parent);
  return true;
}
