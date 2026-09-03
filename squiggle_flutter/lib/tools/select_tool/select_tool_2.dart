import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/tools/editor_interaction.dart';
import 'package:squiggle_flutter/tools/select_tool/select_marquee_interaction.dart';
import 'package:squiggle_flutter/tools/select_tool/select_move_interaction.dart';
import 'package:squiggle_flutter/tools/select_tool/select_polyline_point_interaction.dart';
import 'package:squiggle_flutter/tools/select_tool/select_resize_interaction.dart';
import 'package:squiggle_flutter/tools/tool.dart';

const kSelectionBoxPadding = 8.0;
const kSelectionHandleHitSize = 20.0;
const kSelectionHandlePaintSize = 12.0;
const kDoubleClickInterval = Duration(milliseconds: 300);

class SelectTool2 extends Tool {
  final List<EditorInteraction> _interactions = [
    SelectPolylinePointInteraction(),
    SelectResizeInteraction(),
    SelectMoveInteraction(),
    SelectMarqueeInteraction(),
  ];
  EditorInteraction? _activeInteraction = null;

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    _paintSelectedFeaturesBoxes(canvas, camera, context);

    if (_activeInteraction
        case final PaintableEditorInteraction paintableEditorInteraction) {
      paintableEditorInteraction.paint(
        canvas,
        camera,
        context,
        imageRepository,
      );
    }
  }

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _activeInteraction = null;
    for (final interaction in _interactions) {
      if (!interaction.onPointerDown(
        context,
        worldPosition,
        camera,
        isShiftPressed: isShiftPressed,
        isAltPressed: isAltPressed,
      )) {
        continue;
      }

      _activeInteraction = interaction;
      break;
    }
    return _activeInteraction != null;
  }

  @override
  bool onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (_activeInteraction == null) {
      return false;
    }

    return _activeInteraction!.onPointerMove(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }

  @override
  bool onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (_activeInteraction == null) {
      return false;
    }

    return _activeInteraction!.onPointerUp(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }

  void _paintSelectedFeaturesBoxes(
    Canvas canvas,
    Camera camera,
    EditorContext context,
  ) {
    for (final featureId in context.selection.selectedFeatures) {
      final feature = context.document.featureById(featureId);
      if (feature != null) {
        _paintSelectionBox(canvas, camera, feature.bounds());
      }
    }
  }

  void _paintSelectionBox(Canvas canvas, Camera camera, Rect worldBounds) {
    canvas.save();
    canvas.translate(camera.location.dx, camera.location.dy);
    canvas.scale(camera.zoom, camera.zoom);

    final screenBounds = camera.worldToScreenBounds(worldBounds);
    final inflatedBounds = screenBounds.inflate(
      camera.worldLengthToScreenLength(kSelectionBoxPadding),
    );
    final half = kSelectionHandlePaintSize / 2;

    canvas.drawRect(
      inflatedBounds,
      Paint()
        ..color = SquiggleColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final center in [
      inflatedBounds.topLeft - Offset(half, half),
      inflatedBounds.topRight + Offset(half, -half),
      inflatedBounds.bottomLeft + Offset(-half, half),
      inflatedBounds.bottomRight + Offset(half, half),
    ]) {
      _paintSquareHandleAtScreenCenter(canvas, center);
    }
    canvas.restore();
  }

  void _paintSquareHandleAtScreenCenter(Canvas canvas, Offset center) {
    final handleRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: kSelectionHandlePaintSize,
        height: kSelectionHandlePaintSize,
      ),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(
      handleRRect,
      Paint()
        ..color = SquiggleColors.base
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      handleRRect,
      Paint()
        ..color = SquiggleColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
