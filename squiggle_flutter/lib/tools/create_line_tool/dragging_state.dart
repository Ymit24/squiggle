import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/create_line_tool/interaction_state.dart';

class DraggingState extends InteractionState {
  DraggingState({required super.parent, required this.start});

  final Offset start;

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final end = parent.constrainedPoint(
      start,
      worldPosition,
      isShiftPressed: isShiftPressed,
    );
    parent.updatePreview(context, [start, end]);
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final end = parent.constrainedPoint(
      start,
      worldPosition,
      isShiftPressed: isShiftPressed,
    );
    parent.commit(context, [start, end]);
    parent.cancelInteraction(context);
  }
}
