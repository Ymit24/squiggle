import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/widgets/context_menu.dart';

import '../layer_order_commands_test.dart' show makeContext, order;
import 'context_menu_grouping_test.dart' show openMenu, menuItem;

void main() {
  testWidgets('layer order menu enables valid actions and closes after use', (
    tester,
  ) async {
    final context = makeContext();
    addTearDown(context.dispose);
    final original = order(context);
    context.selection.setSelection([original.first]);
    await openMenu(tester, context);
    expect(menuItem(tester, 'Bring backward').onPressed, isNull);
    expect(menuItem(tester, 'Send to Back').onPressed, isNull);
    expect(menuItem(tester, 'Bring forward').onPressed, isNotNull);
    expect(menuItem(tester, 'Bring to Front').onPressed, isNotNull);
    expect(menuItem(tester, 'Bring to Front').shortcut, '⌘⌥]');
    await tester.tap(find.text('Bring to Front'));
    await tester.pumpAndSettle();
    expect(order(context), [
      original[1],
      original[2],
      original[3],
      original[0],
    ]);
    expect(find.byType(ContextMenu), findsNothing);
    context.undo();
    expect(order(context), original);
  });
}
