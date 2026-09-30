import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/services/duplicate_nodes.dart';

import '../tools/select_tool/select_tool_test_harness.dart';

Feature rectangle(Offset origin) => Feature(
  origin: origin,
  size: const Size(40, 60),
  kind: FeatureKindRectangle(fillColor: const Color(0xFF123456)),
);

Iterable<Node> tree(Node node) sync* {
  yield node;
  if (node is Group) {
    for (final child in node.children) {
      yield* tree(child);
    }
  }
}

void main() {
  test(
    'duplicates sibling trees in paint order with fresh IDs and one edit',
    () {
      final first = rectangle(const Offset(10, 20));
      final nested = Group(origin: const Offset(30, 40), children: [first]);
      final second = rectangle(const Offset(100, 200));
      final parent = Group(
        origin: const Offset(300, 400),
        children: [nested, second],
      );
      final document = Document()..addNode(parent);
      final context = EditorContext(document: document);
      final before = document.toDataModel().toJson();
      context.selection.setSelection([second.id, nested.id]);

      expect(duplicateSelectedNodes(context), isTrue);
      final clones = parent.children.skip(2).toList();
      expect(clones, hasLength(2));
      expect(context.selection.selectedNodeIds, clones.map((node) => node.id));
      expect(clones.map((node) => node.origin), [
        nested.origin + const Offset(16, 16),
        second.origin + const Offset(16, 16),
      ]);
      expect(clones.every((node) => identical(node.parent, parent)), isTrue);
      expect((clones.first as Group).children.single.origin, first.origin);
      final copiedFeature = (clones.first as Group).children.single as Feature;
      expect(copiedFeature.kind.toDataModel(), first.kind.toDataModel());
      expect(copiedFeature.size, first.size);
      final ids = tree(parent).map((node) => node.id).toList();
      expect(ids.toSet(), hasLength(ids.length));
      final after = document.toDataModel().toJson();

      context.undo();
      expect(document.toDataModel().toJson(), before);
      expect(context.history.canUndo, isFalse);
      context.redo();
      expect(document.toDataModel().toJson(), after);
    },
  );

  test(
    'empty, stale, ancestor/descendant and mixed-parent selections are no-ops',
    () {
      final child = rectangle(Offset.zero);
      final group = Group(origin: Offset.zero, children: [child]);
      final sibling = rectangle(const Offset(200, 0));
      final document = Document()..addNodes([group, sibling]);
      final context = EditorContext(document: document);
      final before = document.toDataModel().toJson();
      for (final ids in [
        <NodeId>[],
        [NodeId.newId(999)],
        [child.id, group.id],
        [child.id, sibling.id],
      ]) {
        context.selection.setSelection(ids);
        expect(canDuplicateSelectedNodes(context), isFalse);
        expect(duplicateSelectedNodes(context), isFalse);
        expect(document.toDataModel().toJson(), before);
        expect(context.history.canUndo, isFalse);
      }
    },
  );

  test('command cancels an active move before copying original positions', () {
    final harness = SelectToolTestHarness();
    final original = harness.context.document.nodes.first;
    harness.pointerDown(const Offset(50, 50));
    harness.pointerMove(const Offset(70, 80));
    expect(original.origin, const Offset(20, 30));

    expect(duplicateSelectedNodes(harness.context), isTrue);
    expect(original.origin, Offset.zero);
    final copy = harness.context.document.nodeById(
      harness.context.selection.selectedNodeIds.single,
    )!;
    expect(copy.origin, const Offset(16, 16));
    harness.pointerUp(const Offset(70, 80));
    harness.context.undo();
    expect(harness.context.document.nodes, hasLength(2));
    expect(harness.context.history.canUndo, isFalse);
  });
}
