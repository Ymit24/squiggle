import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';

abstract class InteractionState {
  InteractionState({required this.parent});

  final CreateLineTool parent;

  void onEnter(EditorContext context) {}

  void onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  bool onKeyEvent(EditorContext context, KeyDownEvent event) => false;

  Offset constrainedPoint(
    Offset origin,
    Offset point, {
    required bool isShiftPressed,
  }) => isShiftPressed ? snapPointTo45DegreeAngle(origin, point) : point;
}
