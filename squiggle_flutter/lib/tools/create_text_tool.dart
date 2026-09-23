import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';

class CreateTextTool extends Tool {
  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) => EditorCursor.crosshair;

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {}

  @override
  void deactivate(EditorContext context) {}

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) => true;

  @override
  bool onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) => false;

  @override
  bool onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    context.startTextEdit(
      CreateTextEditSession(
        worldOrigin: worldPosition,
        initialContents: '',
        canvasLocalBounds: camera.worldToScreenBounds(
          newTextBoundsAt(worldPosition),
        ),
      ),
    );
    return true;
  }
}
