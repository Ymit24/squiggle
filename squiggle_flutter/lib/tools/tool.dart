import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

/// Active editor tool: pointer handling and ephemeral overlay painting.
///
/// Tools read and mutate the document via [EditorContext]; gesture mutations
/// are committed to the undo history only when the gesture completes.
abstract class Tool {
  const Tool();

  /// Paints tool-specific overlays after the world transform is applied.
  ///
  /// Most overlays are world-space; selection and vertex handles use [camera]
  /// for screen-constant sizing.
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  );

  void onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  });

  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  });

  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  });

  void onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void deactivate(EditorContext context) {}

  bool onKeyEvent(EditorContext context, KeyDownEvent event) => false;

  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) =>
      EditorCursor.basic;
}
