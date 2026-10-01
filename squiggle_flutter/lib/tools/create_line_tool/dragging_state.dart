import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/create_line_tool/interaction_state.dart';

class DraggingState extends InteractionState {
  DraggingState({required super.parent, required this.start}) : _end = start;

  final Offset start;
  Offset _end;

  @override
  List<Offset> get previewPoints => [start, _end];

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _end = constrainedPoint(
      start,
      worldPosition,
      isShiftPressed: isShiftPressed,
    );
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final end = constrainedPoint(
      start,
      worldPosition,
      isShiftPressed: isShiftPressed,
    );
    parent.commit(context, [start, end]);
    parent.cancelInteraction(context);
  }
}
