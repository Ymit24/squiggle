import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/hit_target.dart';

abstract class InteractionState {
  final SelectTool parent;

  InteractionState({required this.parent});

  void onEnter(EditorContext context) {}

  void onPointerDown(
    EditorContext context,
    HitTarget target,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onDoubleClick(
    EditorContext context,
    HitTarget target,
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

  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    if (event.logicalKey == LogicalKeyboardKey.escape) {
      parent.cancelInteraction(context);
      return true;
    }

    return false;
  }
}
