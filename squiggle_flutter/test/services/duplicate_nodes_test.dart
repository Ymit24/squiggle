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
  test('duplicating only a bound line freezes its current geometry', () {
    final first = rectangle(const Offset(100, 0));
    final second = rectangle(const Offset(300, 0));
    final line = Feature(
      origin: Offset.zero,
      size: Size.zero,
      kind: FeatureKindPolyline([
        Offset.zero,
        const Offset(200, 100),
        const Offset(400, 0),
      ]),
    );
    final document = Document()..addNodes([first, second, line]);
    final kind = line.kind as FeatureKindPolyline;
    kind.startBinding = RadialBinding(first.id, 0);
    kind.endBinding = RadialBinding(second.id, 0);
    // Resolve from the latest target geometry without painting first.
    first.origin += const Offset(20, 40);
    second.size = const Size(80, 100);
    final points = kind.resolvedGlobalPoints(line);
    final before = document.toDataModel();
    final context = EditorContext(document: document);
    context.selection.setSelection([line.id]);

    duplicateSelectedNodes(context);

    final copy = document.featureById(
      context.selection.selectedNodeIds.single,
    )!;
    final copiedKind = copy.kind as FeatureKindPolyline;
    expect(copiedKind.bindings, isEmpty);
    expect(copiedKind.resolvedGlobalPoints(copy), [
      for (final point in points) point + const Offset(64, 64),
    ]);
    expect(line.toDataModel(), before.nodes.last);
    first.origin += const Offset(100, 100);
    expect(copiedKind.resolvedGlobalPoints(copy), [
      for (final point in points) point + const Offset(64, 64),
    ]);
    // Restore the direct target edit before checking the duplicate's history.
    first.origin -= const Offset(100, 100);
    final after = document.toDataModel();
    context.undo();
    expect(document.toDataModel().nodes, before.nodes);
    context.redo();
    expect(document.toDataModel().nodes, after.nodes);
  });

  test(
    'duplicating a nested group remaps internal and detaches external binds',
    () {
      final internal = rectangle(const Offset(100, 0));
      final external = rectangle(const Offset(500, 0));
      final line = Feature(
        origin: const Offset(10, 20),
        size: Size.zero,
        kind: FeatureKindPolyline([Offset.zero, const Offset(200, 50)]),
      );
      final nested = Group(origin: const Offset(30, 40), children: [internal]);
      final group = Group(
        origin: const Offset(200, 100),
        // The source appears before its target in the copied tree.
        children: [line, nested],
      );
      final document = Document()..addNodes([group, external]);
      final kind = line.kind as FeatureKindPolyline;
      kind.startBinding = RadialBinding(internal.id, 0);
      kind.endBinding = RadialBinding(external.id, 0);
      final points = kind.resolvedGlobalPoints(line);
      final context = EditorContext(document: document);
      context.selection.setSelection([group.id]);

      duplicateSelectedNodes(context);

      final copy =
          document.nodeById(context.selection.selectedNodeIds.single) as Group;
      final copiedLine = copy.children.first as Feature;
      final copiedTarget =
          (copy.children.last as Group).children.single as Feature;
      final copiedKind = copiedLine.kind as FeatureKindPolyline;
      expect(copiedKind.startBinding!.targetId, copiedTarget.id);
      expect(copiedKind.endBinding, isNull);
      expect(copiedKind.resolvedGlobalPoints(copiedLine), [
        for (final point in points) point + const Offset(64, 64),
      ]);

      internal.origin += const Offset(10, 0);
      external.origin += const Offset(10, 0);
      expect(copiedKind.resolvedGlobalPoints(copiedLine), [
        for (final point in points) point + const Offset(64, 64),
      ]);
      copiedTarget.origin += const Offset(20, 0);
      expect(
        copiedKind.resolvedGlobalPoints(copiedLine).first,
        points.first + const Offset(84, 64),
      );
    },
  );

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
        nested.origin + const Offset(64, 64),
        second.origin + const Offset(64, 64),
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
    expect(copy.origin, const Offset(64, 64));
    harness.pointerUp(const Offset(70, 80));
    harness.context.undo();
    expect(harness.context.document.nodes, hasLength(2));
    expect(harness.context.history.canUndo, isFalse);
  });
}
