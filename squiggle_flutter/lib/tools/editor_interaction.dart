import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';

/// A focused piece of editor input behavior.
///
/// Returning `true` means that the interaction handled the event. Pointer
/// routers can use a `true` result from pointer-down to capture the rest of
/// the gesture for this interaction.
abstract class EditorInteraction {
  const EditorInteraction();

  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) => false;

  bool onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) => false;

  bool onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) => false;

  bool onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) => false;

  bool onKeyEvent(EditorContext context, KeyDownEvent event) => false;

  void deactivate(EditorContext context) {}
}
