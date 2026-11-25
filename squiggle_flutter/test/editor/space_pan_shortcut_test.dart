import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/widgets/shortcuts/tool_shortcuts.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/tools/pan_tool.dart';

void main() {
  testWidgets('holding space toggles the pan override', (tester) async {
    final editorContext = EditorContext(document: Document());
    addTearDown(editorContext.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<EditorContext>.value(
          value: editorContext,
          child: const ToolShortcuts(child: SizedBox.expand()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(editorContext.tool.isSpacePanning, isTrue);

    await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(editorContext.tool.isSpacePanning, isFalse);

    await tester.sendKeyEvent(LogicalKeyboardKey.keyH);
    await tester.pump();
    expect(editorContext.tool.activeTool, isA<PanTool>());
  });
}
