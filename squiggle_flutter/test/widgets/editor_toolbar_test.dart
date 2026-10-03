import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/editor_toolbar.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/toolbar/button.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

void main() {
  setUpAll(() => Provider.debugCheckInvalidValueType = null);

  testWidgets('lock button toggles and survives manual tool selection', (
    tester,
  ) async {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<EditorContext>.value(
          value: editor,
          child: const Scaffold(body: Stack(children: [EditorToolbar()])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Finder lockButton(IconData icon) => find.byWidgetPredicate(
      (widget) => widget is Button && widget.icon == icon,
    );
    expect(
      tester.widget<Button>(lockButton(LucideIcons.lockOpen)).isActive,
      isFalse,
    );
    expect(tester.widget<Button>(lockButton(LucideIcons.lockOpen)).hotkey, 'Q');
    expect(find.byType(Tooltip), findsNothing);
    await tester.tap(lockButton(LucideIcons.lockOpen));
    await tester.pump();
    expect(editor.tool.isLocked, isTrue);
    expect(
      tester.widget<Button>(lockButton(LucideIcons.lock)).isActive,
      isTrue,
    );

    for (final hotkey in ['2', '1', '3']) {
      await tester.tap(
        find.byWidgetPredicate(
          (widget) => widget is Button && widget.hotkey == hotkey,
        ),
      );
      await tester.pump();
      expect(editor.tool.isLocked, isTrue);
      expect(
        tester.widget<Button>(lockButton(LucideIcons.lock)).isActive,
        isTrue,
      );
    }
    final tool = editor.tool.activeTool;
    await tester.tap(lockButton(LucideIcons.lock));
    await tester.pump();
    expect(editor.tool.isLocked, isFalse);
    expect(editor.tool.activeTool, same(tool));
    expect(
      tester.widget<Button>(lockButton(LucideIcons.lockOpen)).isActive,
      isFalse,
    );
  });

  testWidgets('toolbar highlights the active tool after direct switches', (
    tester,
  ) async {
    final editor = EditorContext(document: Document());
    addTearDown(editor.dispose);
    editor.setTool(CreateFeatureTool.circle());

    await tester.pumpWidget(
      MaterialApp(
        home: RepositoryProvider<EditorContext>.value(
          value: editor,
          child: const Scaffold(body: Stack(children: [EditorToolbar()])),
        ),
      ),
    );
    await tester.pumpAndSettle();

    void expectActive(String hotkey) {
      final buttons = tester.widgetList<Button>(find.byType(Button));
      expect(
        buttons
            .where((button) => button.isActive)
            .map((button) => button.hotkey),
        [hotkey],
      );
    }

    Finder historyButton(IconData icon) => find.byWidgetPredicate(
      (widget) => widget is Button && widget.icon == icon,
    );

    expect(tester.widget<Button>(historyButton(Icons.undo)).onPressed, isNull);
    expect(tester.widget<Button>(historyButton(Icons.redo)).onPressed, isNull);

    expectActive('3');
    for (final (tool, hotkey) in [
      (SelectTool(), '1'),
      (CreateFeatureTool.rect(), '2'),
      (CreateFeatureTool.circle(), '3'),
      (CreateLineTool(), '4'),
      (CreateTextTool(), '5'),
    ]) {
      editor.setTool(tool);
      await tester.pump();
      expectActive(hotkey);
    }

    // A toolbar activation still installs the corresponding tool.
    await tester.tap(
      find.byWidgetPredicate(
        (widget) => widget is Button && widget.hotkey == '2',
      ),
    );
    await tester.pump();
    expectActive('2');

    editor.tool.onPointerDown(
      editor,
      Offset.zero,
      editor.camera,
      isShiftPressed: false,
      isAltPressed: false,
    );
    editor.tool.onPointerMove(
      editor,
      Offset.zero,
      editor.camera,
      isShiftPressed: false,
      isAltPressed: false,
    );
    editor.tool.onPointerMove(
      editor,
      const Offset(100, 100),
      editor.camera,
      isShiftPressed: false,
      isAltPressed: false,
    );
    editor.tool.onPointerUp(
      editor,
      const Offset(100, 100),
      editor.camera,
      isShiftPressed: false,
      isAltPressed: false,
    );
    await tester.pump();

    expectActive('1');
    expect(editor.document.nodes, hasLength(1));
    final undo = tester.widget<Button>(
      find.byWidgetPredicate(
        (widget) => widget is Button && widget.icon == Icons.undo,
      ),
    );
    expect(undo.onPressed, isNotNull);

    await tester.tap(historyButton(Icons.undo));
    await tester.pump();
    expect(editor.document.nodes, isEmpty);
    expect(tester.widget<Button>(historyButton(Icons.undo)).onPressed, isNull);
    expect(
      tester.widget<Button>(historyButton(Icons.redo)).onPressed,
      isNotNull,
    );
    expectActive('1');

    await tester.tap(historyButton(Icons.redo));
    await tester.pump();
    expect(editor.document.nodes, hasLength(1));
    expect(
      tester.widget<Button>(historyButton(Icons.undo)).onPressed,
      isNotNull,
    );
    expect(tester.widget<Button>(historyButton(Icons.redo)).onPressed, isNull);

    editor.history.clear();
    await tester.pump();
    expect(tester.widget<Button>(historyButton(Icons.undo)).onPressed, isNull);
    expect(tester.widget<Button>(historyButton(Icons.redo)).onPressed, isNull);
  });
}
