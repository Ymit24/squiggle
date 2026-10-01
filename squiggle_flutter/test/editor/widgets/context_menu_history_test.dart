import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/widgets/context_menu.dart';

import '../layer_order_commands_test.dart' show makeContext;
import 'context_menu_grouping_test.dart' show openMenu, menuItem;

void main() {
  for (final selected in [false, true]) {
    testWidgets('empty history disables actions with selected=$selected', (
      tester,
    ) async {
      final context = makeContext();
      addTearDown(context.dispose);
      if (selected) {
        context.selection.setSelection([context.document.nodes.first.id]);
      }
      await openMenu(tester, context);
      expect(menuItem(tester, 'Undo').onPressed, isNull);
      expect(menuItem(tester, 'Redo').onPressed, isNull);
      expect(menuItem(tester, 'Undo').shortcut, '⌘Z');
      expect(menuItem(tester, 'Redo').shortcut, '⇧⌘Z');
      await tester.tap(find.text('Undo'));
      await tester.tap(find.text('Redo'));
      await tester.pumpAndSettle();
      expect(find.byType(ContextMenu), findsOneWidget);
    });

    testWidgets('menu restores edits and closes with selected=$selected', (
      tester,
    ) async {
      final context = makeContext();
      addTearDown(context.dispose);
      final removed = context.document.nodes.first;
      final before = context.document.toDataModel().nodes;
      context.history.run('Delete', (transaction) {
        transaction.removeAll([removed.id]);
      });
      final after = context.document.toDataModel().nodes;
      if (selected) {
        context.selection.setSelection([context.document.nodes.first.id]);
      }

      await openMenu(tester, context);
      expect(menuItem(tester, 'Undo').onPressed, isNotNull);
      expect(menuItem(tester, 'Redo').onPressed, isNull);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(context.document.toDataModel().nodes, before);
      expect(find.byType(ContextMenu), findsNothing);

      // Redo must also remove stale selection through EditorContext.
      if (selected) context.selection.setSelection([removed.id]);
      await openMenu(tester, context);
      expect(menuItem(tester, 'Undo').onPressed, isNull);
      expect(menuItem(tester, 'Redo').onPressed, isNotNull);
      await tester.tap(find.text('Redo'));
      await tester.pumpAndSettle();
      expect(context.document.toDataModel().nodes, after);
      expect(context.selection.isEmpty, isTrue);
      expect(find.byType(ContextMenu), findsNothing);
    });
  }
}
