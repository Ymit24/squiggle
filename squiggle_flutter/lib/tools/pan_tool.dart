import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';

/// Pans the camera by dragging, keeping the grab point under the cursor.
///
/// Uses incremental screen-space deltas so panning stays correct even when the
/// camera is zoomed mid-drag (e.g. scroll-wheel zoom toward a focal point).
class PanTool extends Tool {
  PanTool();

  bool _isPanning = false;
  Offset? _lastScreenPosition;

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) =>
      _isPanning ? EditorCursor.grabbing : EditorCursor.grab;

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {}

  @override
  void deactivate(EditorContext context) {
    _isPanning = false;
    _lastScreenPosition = null;
  }

  @override
  void onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _isPanning = true;
    _lastScreenPosition = camera.worldToScreen(worldPosition);
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final lastScreen = _lastScreenPosition;
    if (!_isPanning || lastScreen == null) return;
    // worldPosition is derived from the already-shifted camera, so recover the
    // true cursor position in screen space before mutating the camera.
    final currentScreen = camera.worldToScreen(worldPosition);
    camera.panByScreenDelta(currentScreen - lastScreen);
    _lastScreenPosition = currentScreen;
    context.notifyViewportChanged();
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _isPanning = false;
    _lastScreenPosition = null;
  }
}
