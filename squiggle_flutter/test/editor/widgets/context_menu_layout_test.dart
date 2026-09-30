import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/widgets/context_menu.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/node_layout_selector.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';

import 'context_menu_grouping_test.dart' show openMenu;

EditorContext layoutContext() => EditorContext(
  document: Document.fromFeatures([
    for (final origin in [
      Offset.zero,
      const Offset(30, 20),
      const Offset(100, 100),
    ])
      Feature(
        origin: origin,
        size: const Size(10, 10),
        kind: FeatureKindRectangle(),
      ),
  ]),
);

void main() {
  for (final count in [0, 1, 2, 3]) {
    testWidgets('layout availability with $count selected nodes', (
      tester,
    ) async {
      final context = layoutContext();
      addTearDown(context.dispose);
      context.selection.setSelection(
        context.document.nodes.take(count).map((node) => node.id),
      );
      await openMenu(tester, context);
      if (count == 0) {
        expect(find.text('Align'), findsNothing);
        expect(find.text('Distribute'), findsNothing);
      } else {
        expect(
          tester
              .widget<NodeAlignSelector>(find.byType(NodeAlignSelector))
              .enabled,
          count >= 2,
        );
        expect(
          tester
              .widget<NodeDistributeSelector>(
                find.byType(NodeDistributeSelector),
              )
              .enabled,
          count >= 3,
        );
        if (count < 3) {
          await tester.tap(find.byTooltip('Distribute horizontally'));
          await tester.pumpAndSettle();
          expect(find.byType(ContextMenu), findsOneWidget);
          expect(context.history.canUndo, isFalse);
        }
      }
    });
  }

  for (final invalidSelection in ['different parents', 'missing node']) {
    testWidgets('$invalidSelection disables layout controls', (tester) async {
      final context = layoutContext();
      addTearDown(context.dispose);
      final nodes = context.document.nodes.toList();
      if (invalidSelection == 'different parents') {
        context.document.removeAll([nodes.first.id]);
        context.document.addNode(
          Group(origin: Offset.zero, children: [nodes.first]),
        );
      }
      context.selection.setSelection([
        ...nodes.map((node) => node.id),
        if (invalidSelection == 'missing node') NodeId.newId(999),
      ]);
      await openMenu(tester, context);
      expect(
        tester
            .widget<NodeAlignSelector>(find.byType(NodeAlignSelector))
            .enabled,
        isFalse,
      );
      expect(
        tester
            .widget<NodeDistributeSelector>(find.byType(NodeDistributeSelector))
            .enabled,
        isFalse,
      );
    });
  }

  for (final (_, action, expected) in [
    (
      'Align',
      'Align left',
      [Offset.zero, const Offset(0, 20), const Offset(0, 100)],
    ),
    (
      'Distribute',
      'Distribute horizontally',
      [Offset.zero, const Offset(50, 20), const Offset(100, 100)],
    ),
    (
      'Distribute',
      'Distribute vertically',
      [Offset.zero, const Offset(30, 50), const Offset(100, 100)],
    ),
  ]) {
    testWidgets(
      '$action on nested siblings closes menu and supports undo/redo',
      (tester) async {
        final context = layoutContext();
        addTearDown(context.dispose);
        final nodes = context.document.nodes.toList();
        context.document.removeAll(nodes.map((node) => node.id));
        context.document.addNode(
          Group(origin: const Offset(300, 400), children: nodes),
        );
        context.selection.setSelection(nodes.reversed.map((node) => node.id));
        final selectedIds = context.selection.selectedNodeIds;
        final before = context.document.toDataModel().nodes;
        await openMenu(tester, context);
        await tester.tap(find.byTooltip(action));
        await tester.pumpAndSettle();
        expect(find.byType(ContextMenu), findsNothing);
        expect(nodes.map((node) => node.origin), expected);
        expect(context.selection.selectedNodeIds, selectedIds);
        final after = context.document.toDataModel().nodes;
        context.undo();
        expect(context.document.toDataModel().nodes, before);
        expect(context.history.canUndo, isFalse);
        context.redo();
        expect(context.document.toDataModel().nodes, after);
      },
    );
  }
}
