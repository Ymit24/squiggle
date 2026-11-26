import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';

/// Drags the viewport. Used by the hand tool and by the hold-space override.
class PanTool extends Tool {
  Offset? _lastScreen;

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) => _lastScreen == null ? EditorCursor.grab : EditorCursor.grabbing;

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    context.cancelViewportMotion();
    _lastScreen = camera.worldToScreen(worldPosition);
    return true;
  }

  @override
  bool onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final lastScreen = _lastScreen;
    if (lastScreen == null) return false;

    final screen = camera.worldToScreen(worldPosition);
    context.panByScreenDelta(screen - lastScreen);
    _lastScreen = screen;
    return true;
  }

  @override
  bool onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _lastScreen = null;
    return true;
  }

  @override
  void cancelInteraction(EditorContext context) => _lastScreen = null;

  @override
  void deactivate(EditorContext context) => cancelInteraction(context);

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {}
}
