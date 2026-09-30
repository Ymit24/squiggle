import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/shortcuts/shortcuts.dart';
import 'package:squiggle_flutter/editor/widgets/context_menu.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';

EditorContext selectedContext() {
  final context = EditorContext(
    document: Document.fromFeatures([
      Feature(
        origin: const Offset(10, 20),
        size: const Size(40, 60),
        kind: FeatureKindRectangle(),
      ),
      Feature(
        origin: const Offset(100, 200),
        size: const Size(50, 70),
        kind: FeatureKindCircle(),
      ),
    ]),
  );
  context.selection.setSelection(context.document.nodes.map((node) => node.id));
  return context;
}

Future<void> pressDuplicate(
  WidgetTester tester,
  LogicalKeyboardKey modifier,
) async {
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyD);
  await tester.sendKeyUpEvent(modifier);
  await tester.pump();
}

void expectDuplicationAndReplay(EditorContext context) {
  final nodes = context.document.nodes;
  expect(nodes, hasLength(4));
  expect(
    context.selection.selectedNodeIds,
    nodes.skip(2).map((node) => node.id),
  );
  for (var i = 0; i < 2; i++) {
    expect(nodes[i + 2].id, isNot(nodes[i].id));
    expect(nodes[i + 2].origin, nodes[i].origin + const Offset(64, 64));
  }
  final after = context.document.toDataModel().toJson();
  context.undo();
  expect(context.document.nodes, hasLength(2));
  expect(context.history.canUndo, isFalse);
  context.redo();
  expect(context.document.toDataModel().toJson(), after);
}

Future<void> pumpShortcuts(
  WidgetTester tester,
  EditorContext context, {
  bool textEditOpen = false,
  Widget child = const SizedBox.expand(),
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: RepositoryProvider<EditorContext>.value(
        value: context,
        child: Material(
          child: ToolShortcuts(textEditOpen: textEditOpen, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => Provider.debugCheckInvalidValueType = null);

  for (final modifier in [
    LogicalKeyboardKey.meta,
    LogicalKeyboardKey.control,
  ]) {
    testWidgets('$modifier + D duplicates and supports undo/redo', (
      tester,
    ) async {
      final context = selectedContext();
      await pumpShortcuts(tester, context);
      await pressDuplicate(tester, modifier);
      expectDuplicationAndReplay(context);
    });

    testWidgets('$modifier + D leaves text editing active', (tester) async {
      final context = selectedContext();
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await pumpShortcuts(
        tester,
        context,
        textEditOpen: true,
        child: TextField(focusNode: focus),
      );
      focus.requestFocus();
      await tester.pump();
      await pressDuplicate(tester, modifier);
      expect(focus.hasFocus, isTrue);
      expect(context.document.nodes, hasLength(2));
      expect(context.history.canUndo, isFalse);
    });
  }

  testWidgets('shortcut is a no-op for empty and unsupported selection', (
    tester,
  ) async {
    final context = selectedContext();
    await pumpShortcuts(tester, context);
    for (final ids in [
      <NodeId>[],
      [NodeId.newId(999)],
    ]) {
      context.selection.setSelection(ids);
      await pressDuplicate(tester, LogicalKeyboardKey.control);
      expect(context.document.nodes, hasLength(2));
      expect(context.history.canUndo, isFalse);
    }
  });

  testWidgets('context menu Duplicate selects copies and supports undo/redo', (
    tester,
  ) async {
    final context = selectedContext();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (buildContext) => Scaffold(
            body: TextButton(
              onPressed: () => context.openContextMenuAt(
                buildContext,
                const Offset(30, 30),
                const Offset(500, 500),
                imageRepository: ImageRepository(),
              ),
              child: const Text('Open menu'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open menu'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Duplicate'));
    await tester.pumpAndSettle();
    expect(find.byType(ContextMenu), findsNothing);
    expectDuplicationAndReplay(context);
  });

  testWidgets(
    'menu disables Duplicate for unsupported selections and omits it when empty',
    (tester) async {
      final context = selectedContext();
      final child = Feature(
        origin: Offset.zero,
        size: const Size(20, 20),
        kind: FeatureKindRectangle(),
      );
      final group = Group(origin: Offset.zero, children: [child]);
      context.document.addNode(group);
      for (final ids in [
        [NodeId.newId(999)],
        [group.id, child.id],
        [context.document.nodes.first.id, child.id],
        <NodeId>[],
      ]) {
        context.selection.setSelection(ids);
        await tester.pumpWidget(
          MaterialApp(
            home: Stack(
              children: [
                ContextMenu(
                  key: UniqueKey(),
                  localScreenPosition: const Offset(30, 30),
                  editorContext: context,
                  imageRepository: ImageRepository(),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final items = tester
            .widgetList<SquiggleMenuItem>(find.byType(SquiggleMenuItem))
            .where((item) => item.label == 'Duplicate');
        if (ids.isEmpty) {
          expect(items, isEmpty);
        } else {
          expect(items.single.onPressed, isNull);
        }
      }
    },
  );
}
