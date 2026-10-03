import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';

/// Input and overlay hooks for a tool's current interaction.
///
/// Concrete states retain access to their tool-specific helpers through [parent].
abstract class InteractionState<T extends Tool> {
  InteractionState({required this.parent});
  final T parent;

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

  void onDoubleClick(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {}

  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {}

  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return EditorCursor.basic;
  }

  bool onKeyEvent(EditorContext context, KeyDownEvent event) => false;
}
