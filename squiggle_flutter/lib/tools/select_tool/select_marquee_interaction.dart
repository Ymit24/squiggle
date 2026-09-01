import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/editor_interaction.dart';

/// Select-tool interaction for dragging a selected polyline vertex.
class SelectMarqueeInteraction extends EditorInteraction {
  Offset? _start;

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
    return true;
  }

  @override
  void deactivate(EditorContext context) => _start = null;
}

/// Select-tool interaction for moving the current selection.
