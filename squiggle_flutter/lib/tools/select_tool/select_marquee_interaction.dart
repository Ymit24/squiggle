import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_interaction.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/utils/painting.dart';

/// Select-tool interaction for dragging a selected polyline vertex.
class SelectMarqueeInteraction extends EditorInteraction
    implements PaintableEditorInteraction {
  Offset? _start;
  Offset? _end;

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    final start = _start;
    final end = _end;
    if (start == null || end == null) return;

    final bounds = Rect.fromPoints(start, end);
    canvas.drawRect(
      bounds,
      Paint()
        ..color = SquiggleColors.selectionFill
        ..style = PaintingStyle.fill,
    );
    paintDashedRect(canvas, bounds);
  }

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (context.document.featureAtPoint(worldPosition) != null) return false;
    _start = worldPosition;
    _end = worldPosition;
    if (!isShiftPressed) context.selection.clearSelection();
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
    final start = _start;
    if (start == null) return false;
    _end = worldPosition;
    final bounds = Rect.fromPoints(start, worldPosition);
    final ids = context.document.nodes
        .where((f) => f.intersectsRect(bounds))
        .map((f) => f.id)
        .toList();
    if (isShiftPressed) {
      for (final id in ids) {
        context.selection.selectFeature(id);
      }
    } else {
      context.selection.setSelection(ids);
    }
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
    _start = null;
    _end = null;
    return true;
  }

  @override
  void deactivate(EditorContext context) {
    _start = null;
    _end = null;
  }
}
