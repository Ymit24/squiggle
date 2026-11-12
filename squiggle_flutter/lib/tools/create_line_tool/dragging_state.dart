import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/interaction_state.dart';
import 'package:squiggle_flutter/tools/pointer_modifiers.dart';

class DraggingState extends InteractionState<CreateLineTool> {
  DraggingState({required super.parent, required this.start});

  final Offset start;

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required PointerModifiers modifiers,
  }) {
    final end = parent.constrainedPoint(
      start,
      worldPosition,
      isShiftPressed: modifiers.shift,
    );
    parent.updatePreview(context, [start, end]);
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required PointerModifiers modifiers,
  }) {
    final end = parent.constrainedPoint(
      start,
      worldPosition,
      isShiftPressed: modifiers.shift,
    );
    parent.finish(context, [start, end]);
  }
}
