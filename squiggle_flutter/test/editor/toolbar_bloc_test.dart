import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';

void main() {
  test('toolbar reflects automatic switch to select after drawing', () async {
    final context = EditorContext(document: Document());
    final bloc = ToolbarBloc(context: context)
      ..add(const RequestWatchToolbarStateEvent());
    addTearDown(() async {
      await bloc.close();
      context.dispose();
    });

    bloc.add(const ActivateCreateRectToolEvent());
    await bloc.stream.firstWhere(
      (state) => state.activeTool == ActiveToolKind.createRect,
    );

    final camera = Camera();
    context.tool.onPointerDown(
      context,
      Offset.zero,
      camera,
      isShiftPressed: false,
      isAltPressed: false,
    );
    context.tool.onPointerMove(
      context,
      const Offset(100, 100),
      camera,
      isShiftPressed: false,
      isAltPressed: false,
    );
    context.tool.onPointerUp(
      context,
      const Offset(100, 100),
      camera,
      isShiftPressed: false,
      isAltPressed: false,
    );

    final state = await bloc.stream.firstWhere(
      (state) => state.activeTool == ActiveToolKind.select,
    );
    expect(state.canUndo, isTrue);
  });
}
