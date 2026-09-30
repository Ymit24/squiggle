import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/widgets/context_menu.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';

import '../../tools/select_tool/select_tool_test_harness.dart';

Future<void> openMenu(WidgetTester tester, EditorContext context) async {
  tester.view.physicalSize = const Size(1000, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final images = ImageRepository();
  addTearDown(images.dispose);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      home: const Scaffold(body: Text('Editor')),
    ),
  );
  navigator.currentState!.push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        body: Stack(
          children: [
            ContextMenu(
              localScreenPosition: const Offset(20, 20),
              editorContext: context,
              imageRepository: images,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

SquiggleMenuItem menuItem(WidgetTester tester, String label) =>
    tester.widget<SquiggleMenuItem>(
      find.byWidgetPredicate(
        (widget) => widget is SquiggleMenuItem && widget.label == label,
      ),
    );

void main() {
  testWidgets('menu groups nested siblings in paint order with undo/redo', (
    tester,
  ) async {
    final context = SelectToolTestHarness.defaultContext();
    final document = context.document;
    final first = document.nodes.first;
    final second = document.nodes.last;
    final middle = second.copyWith(id: noId, origin: const Offset(150, 20));
    document.removeAll([first.id, second.id]);
    final parent =
        document.addNode(
              Group(
                origin: const Offset(300, 400),
                children: [first, middle, second],
              ),
            )
            as Group;
    context.selection.setSelection([second.id, first.id]);
    final before = document.toDataModel().nodes;
    final bounds = [first.globalBounds(), second.globalBounds()];

    await openMenu(tester, context);
    expect(menuItem(tester, 'Group').onPressed, isNotNull);
    expect(menuItem(tester, 'Group').shortcut, '⌘G');
    expect(menuItem(tester, 'Ungroup').onPressed, isNull);
    await tester.tap(find.text('Group'));
    await tester.pumpAndSettle();
    expect(find.byType(ContextMenu), findsNothing);
    expect(find.text('Editor'), findsOneWidget);

    final group = parent.children.last as Group;
    expect(document.nodes.single, parent);
    expect(parent.children, [middle, group]);
    expect(group.children.map((node) => node.id), [first.id, second.id]);
    expect(group.children.map((node) => node.globalBounds()), bounds);
    expect(group.parent, parent);
    expect(context.selection.selectedNodeIds, [group.id]);
    final grouped = document.toDataModel().nodes;
    context.history.undo();
    expect(document.toDataModel().nodes, before);
    expect(context.history.canUndo, isFalse);
    context.history.redo();
    expect(document.toDataModel().nodes, grouped);
  });

  testWidgets('menu ungroups multiple nested groups in a mixed selection', (
    tester,
  ) async {
    final context = SelectToolTestHarness.defaultContext();
    final document = context.document;
    final first = document.nodes.first;
    final second = document.nodes.last;
    final middle = second.copyWith(id: noId, origin: const Offset(150, 20));
    document.removeAll([first.id, second.id]);
    final firstGroup = Group(origin: const Offset(30, 40), children: [first]);
    final secondGroup = Group(origin: const Offset(50, 60), children: [second]);
    final parent =
        document.addNode(
              Group(
                origin: const Offset(300, 400),
                children: [firstGroup, middle, secondGroup],
              ),
            )
            as Group;
    context.selection.setSelection([secondGroup.id, middle.id, firstGroup.id]);
    final before = document.toDataModel().nodes;
    final bounds = [first.globalBounds(), second.globalBounds()];
    final middleBefore = middle.toDataModel();

    await openMenu(tester, context);
    expect(menuItem(tester, 'Ungroup').onPressed, isNotNull);
    expect(menuItem(tester, 'Ungroup').shortcut, '⇧⌘G');
    await tester.tap(find.text('Ungroup'));
    await tester.pumpAndSettle();
    expect(find.byType(ContextMenu), findsNothing);
    expect(document.nodes.single, parent);
    expect(parent.children, [first, middle, second]);
    expect([first.globalBounds(), second.globalBounds()], bounds);
    expect(middle.toDataModel(), middleBefore);
    expect(parent.children.every((node) => node.parent == parent), isTrue);
    expect(context.selection.selectedNodeIds, [second.id, first.id]);
    final ungrouped = document.toDataModel().nodes;
    context.history.undo();
    expect(document.toDataModel().nodes, before);
    expect(context.history.canUndo, isFalse);
    context.history.redo();
    expect(document.toDataModel().nodes, ungrouped);
  });

  for (final selection in [
    'empty',
    'single',
    'different parents',
    'groups with different parents',
  ]) {
    testWidgets('$selection disables inappropriate menu actions', (
      tester,
    ) async {
      final context = SelectToolTestHarness.defaultContext();
      final document = context.document;
      final nodes = document.nodes.toList();
      switch (selection) {
        case 'single':
          context.selection.setSelection([nodes.first.id]);
        case 'different parents':
          document.removeAll([nodes.first.id]);
          document.addNode(Group(origin: Offset.zero, children: [nodes.first]));
          context.selection.setSelection(nodes.map((node) => node.id));
        case 'groups with different parents':
          document.removeAll(nodes.map((node) => node.id));
          final inner = Group(origin: Offset.zero, children: [nodes.first]);
          document.addNode(Group(origin: Offset.zero, children: [inner]));
          final outer = document.addNode(
            Group(origin: Offset.zero, children: [nodes.last]),
          );
          context.selection.setSelection([inner.id, outer.id]);
      }
      final before = document.toDataModel().nodes;
      final selectedIds = context.selection.selectedNodeIds.toList();
      await openMenu(tester, context);
      expect(menuItem(tester, 'Group').onPressed, isNull);
      expect(menuItem(tester, 'Ungroup').onPressed, isNull);
      await tester.tap(find.text('Group'));
      await tester.tap(find.text('Ungroup'));
      await tester.pumpAndSettle();
      expect(find.byType(ContextMenu), findsOneWidget);
      expect(document.toDataModel().nodes, before);
      expect(context.selection.selectedNodeIds, selectedIds);
      expect(context.history.canUndo, isFalse);
    });
  }

  testWidgets('a single group enables only Ungroup', (tester) async {
    final context = SelectToolTestHarness.defaultContext();
    final document = context.document;
    final children = document.nodes.toList();
    document.removeAll(children.map((node) => node.id));
    final group = document.addNode(
      Group(origin: Offset.zero, children: children),
    );
    context.selection.setSelection([group.id]);
    await openMenu(tester, context);
    expect(menuItem(tester, 'Group').onPressed, isNull);
    expect(menuItem(tester, 'Ungroup').onPressed, isNotNull);
  });
}
