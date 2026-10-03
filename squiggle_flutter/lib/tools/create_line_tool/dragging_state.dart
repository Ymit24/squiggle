import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/binding_candidate.dart';
import 'package:squiggle_flutter/tools/interaction_state.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';

class DraggingState extends InteractionState<CreateLineTool> {
  DraggingState({required super.parent, required this.start});

  final Offset start;
  BindingCandidate? _startBinding;

  @override
  void onEnter(EditorContext context) {
    _startBinding = BindingCandidate.at(context.document, start);
  }

  List<Offset> _points(
    EditorContext context,
    Offset pointer, {
    required bool isShiftPressed,
  }) {
    parent.hoveredBinding = BindingCandidate.at(context.document, pointer);
    final origin = _startBinding?.point ?? start;
    final end =
        parent.hoveredBinding?.point ??
        parent.constrainedPoint(
          origin,
          pointer,
          isShiftPressed: isShiftPressed,
        );
    return [origin, end];
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    parent.updatePreview(
      context,
      _points(context, worldPosition, isShiftPressed: isShiftPressed),
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
    final points = _points(
      context,
      worldPosition,
      isShiftPressed: isShiftPressed,
    );
    parent.finish(
      context,
      points,
      startBinding: _startBinding?.binding,
      endBinding: parent.hoveredBinding?.binding,
    );
  }
}
