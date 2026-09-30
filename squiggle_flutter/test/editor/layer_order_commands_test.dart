import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/layer_order_commands.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';

EditorContext makeContext() => EditorContext(
  document: Document.fromFeatures([
    for (var i = 0; i < 4; i++)
      Feature(
        origin: Offset(i * 10.0, 0),
        size: const Size(10, 10),
        kind: FeatureKindRectangle(),
      ),
  ]),
);

List<NodeId> order(EditorContext context) =>
    context.document.nodes.map((node) => node.id).toList();

void main() {
  test('each action preserves selection and supports undo/redo', () {
    for (final (action, expected) in [
      (LayerOrder.backward, [1, 0, 2, 3]),
      (LayerOrder.forward, [0, 2, 1, 3]),
      (LayerOrder.back, [1, 0, 2, 3]),
      (LayerOrder.front, [0, 2, 3, 1]),
    ]) {
      final context = makeContext();
      final original = order(context);
      context.selection.setSelection([original[1]]);
      expect(canReorderSelectedNodes(context, action), isTrue);
      reorderSelectedNodes(context, action);
      expect(order(context), [for (final index in expected) original[index]]);
      expect(context.selection.selectedNodeIds, [original[1]]);
      expect(context.history.canUndo, isTrue);
      context.undo();
      expect(order(context), original);
      context.redo();
      expect(order(context), [for (final index in expected) original[index]]);
      context.dispose();
    }
  });

  test('adjacent selected nodes move together in paint order', () {
    final context = makeContext();
    final original = order(context);
    context.selection.setSelection([original[2], original[1]]);
    reorderSelectedNodes(context, LayerOrder.forward);
    expect(order(context), [
      original[0],
      original[3],
      original[1],
      original[2],
    ]);
    reorderSelectedNodes(context, LayerOrder.back);
    expect(order(context), [
      original[1],
      original[2],
      original[0],
      original[3],
    ]);
    context.dispose();
  });

  test('nested siblings reorder without moving their parent', () {
    final context = makeContext();
    final children = context.document.nodes.toList();
    context.document.removeAll(children.map((node) => node.id));
    final group =
        context.document.addNode(Group(origin: Offset.zero, children: children))
            as Group;
    context.selection.setSelection([children.first.id]);
    reorderSelectedNodes(context, LayerOrder.front);
    expect(group.children.last.id, children.first.id);
    expect(context.document.nodes, [group]);
    context.undo();
    expect(group.children, children);
    context.dispose();
  });

  test('boundary and invalid selections create no edit', () {
    final context = makeContext();
    final original = order(context);
    context.selection.setSelection([original.first]);
    expect(canReorderSelectedNodes(context, LayerOrder.backward), isFalse);
    reorderSelectedNodes(context, LayerOrder.backward);
    expect(context.history.canUndo, isFalse);
    context.selection.setSelection(original);
    expect(canReorderSelectedNodes(context, LayerOrder.front), isFalse);
    context.selection.setSelection([original[1], NodeId.newId(999)]);
    expect(canReorderSelectedNodes(context, LayerOrder.front), isFalse);
    context.dispose();
  });
}
