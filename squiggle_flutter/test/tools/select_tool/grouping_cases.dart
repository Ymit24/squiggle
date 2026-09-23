import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';

import 'select_tool_test_harness.dart';

void main() {
  test('click and marquee select a group rather than its descendants', () {
    final harness = SelectToolTestHarness();
    final document = harness.context.document;
    final children = document.nodes.toList();
    document.removeAll(children.map((node) => node.id));
    final group = Group(origin: const Offset(100, 200), children: children);
    document.addNode(group);

    // The point is in the gap between the two children.
    harness.click(const Offset(250, 250));
    expect(harness.context.selection.selectedNodeIds, [group.id]);
    harness.context.selection.clearSelection();
    harness.pointerDown(const Offset(240, 180));
    harness.pointerMove(const Offset(260, 260));
    harness.pointerUp(const Offset(260, 260));
    expect(harness.context.selection.selectedNodeIds, [group.id]);

    final before = document.toDataModel().nodes;
    expect(harness.keyDown(LogicalKeyboardKey.delete), isTrue);
    expect(document.nodes, isEmpty);
    expect(harness.context.selection.selectedNodeIds, isEmpty);
    harness.context.history.undo();
    expect(document.toDataModel().nodes, before);
    for (final child in children) {
      expect(document.nodeById(child.id)?.parent?.children, hasLength(2));
    }
  });

  for (final modifier in [
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.metaLeft,
  ]) {
    testWidgets(
      '${modifier.keyLabel}+G groups and Shift ungroups with history',
      (tester) async {
        final harness = SelectToolTestHarness();
        final context = harness.context;
        final document = context.document;
        final ids = document.nodes.map((node) => node.id).toList();
        final bounds = document.nodes
            .map((node) => node.globalBounds())
            .toList();
        final before = document.toDataModel().nodes;
        context.selection.setSelection(ids);

        await tester.sendKeyDownEvent(modifier);
        try {
          expect(harness.keyDown(LogicalKeyboardKey.keyG), isTrue);
          final group = document.nodes.single as Group;
          expect(context.selection.selectedNodeIds, [group.id]);
          expect(group.children.map((node) => node.id), ids);
          expect(group.children.map((node) => node.globalBounds()), bounds);
          expect(group.children.every((node) => node.parent == group), isTrue);
          final grouped = document.toDataModel().nodes;

          context.history.undo();
          expect(document.toDataModel().nodes, before);
          expect(context.history.canUndo, isFalse);
          context.history.redo();
          expect(document.toDataModel().nodes, grouped);
          context.selection.setSelection([group.id]);

          await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
          try {
            expect(harness.keyDown(LogicalKeyboardKey.keyG), isTrue);
          } finally {
            await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
          }
          expect(document.nodes.map((node) => node.id), ids);
          expect(document.nodes.map((node) => node.globalBounds()), bounds);
          expect(context.selection.selectedNodeIds, ids);
          expect(
            document.nodes.every((node) => node.parent == document),
            isTrue,
          );
          final ungrouped = document.toDataModel().nodes;
          context.history.undo();
          expect(document.toDataModel().nodes, grouped);
          context.history.redo();
          expect(document.toDataModel().nodes, ungrouped);
        } finally {
          await tester.sendKeyUpEvent(modifier);
        }
      },
    );
  }

  testWidgets('group shortcuts leave empty and single selections unchanged', (
    tester,
  ) async {
    final harness = SelectToolTestHarness();
    final context = harness.context;
    final before = context.document.toDataModel().nodes;
    expect(harness.keyDown(LogicalKeyboardKey.keyG), isFalse);
    context.selection.setSelection(
      context.document.nodes.map((node) => node.id),
    );
    expect(harness.keyDown(LogicalKeyboardKey.keyG), isFalse);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    try {
      context.selection.clearSelection();
      expect(harness.keyDown(LogicalKeyboardKey.keyG), isFalse);
      context.selection.selectNode(context.document.nodes.first.id);
      expect(harness.keyDown(LogicalKeyboardKey.keyG), isTrue);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      try {
        expect(harness.keyDown(LogicalKeyboardKey.keyG), isTrue);
      } finally {
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      }
      expect(context.document.toDataModel().nodes, before);
      expect(context.history.canUndo, isFalse);
    } finally {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }
  });

  testWidgets('grouping preserves sibling and child paint order', (
    tester,
  ) async {
    final harness = SelectToolTestHarness();
    final document = harness.context.document;
    final first = document.nodes[0];
    final second = document.nodes[1];
    final third = document.addNode(
      second.copyWith(id: noId, origin: const Offset(400, 0)),
    );
    harness.context.selection.setSelection([second.id, first.id]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    try {
      expect(harness.keyDown(LogicalKeyboardKey.keyG), isTrue);
    } finally {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    final group = document.nodes.first as Group;
    expect(document.nodes, [group, third]);
    expect(group.children.map((node) => node.id), [first.id, second.id]);
    harness.context.history.undo();
    expect(document.nodes.map((node) => node.id), [
      first.id,
      second.id,
      third.id,
    ]);
  });

  testWidgets('ungrouping multiple groups is one undo entry', (tester) async {
    final harness = SelectToolTestHarness();
    final document = harness.context.document;
    final children = document.nodes.toList();
    document.removeAll(children.map((node) => node.id));
    final firstGroup = document.addNode(
      Group(origin: Offset.zero, children: [children.first]),
    );
    final secondGroup = document.addNode(
      Group(origin: Offset.zero, children: [children.last]),
    );
    harness.context.selection.setSelection([firstGroup.id, secondGroup.id]);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    try {
      expect(harness.keyDown(LogicalKeyboardKey.keyG), isTrue);
    } finally {
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    }

    expect(document.nodes.whereType<Group>(), isEmpty);
    expect(harness.context.history.canUndo, isTrue);
    harness.context.history.undo();
    expect(document.nodes.whereType<Group>(), hasLength(2));
    expect(harness.context.history.canUndo, isFalse);
  });
}
