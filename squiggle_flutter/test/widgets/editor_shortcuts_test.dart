import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/widgets/toolbar.dart';

void main() {
  testWidgets('EditorShortcuts activates tools on V, R, C keys', (tester) async {
    final toolRepository = ToolRepository();
    final selectionRepository = SelectionRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider(
            create: (_) => ToolbarBloc(
              toolRepository: toolRepository,
              selectionRepository: selectionRepository,
            ),
            child: EditorShortcuts(
              child: const SizedBox.expand(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final toolbarBloc = tester.element(find.byType(EditorShortcuts)).read<ToolbarBloc>();

    Future<void> pressKey(LogicalKeyboardKey key) async {
      await tester.sendKeyEvent(key, platform: 'macos');
      await tester.pump();
    }

    await pressKey(LogicalKeyboardKey.keyR);
    expect(
      toolbarBloc.state.activeTool,
      ActiveToolKind.createRect,
    );

    await pressKey(LogicalKeyboardKey.keyC);
    expect(
      toolbarBloc.state.activeTool,
      ActiveToolKind.createCircle,
    );

    await pressKey(LogicalKeyboardKey.keyV);
    expect(
      toolbarBloc.state.activeTool,
      ActiveToolKind.select,
    );
  });
}
