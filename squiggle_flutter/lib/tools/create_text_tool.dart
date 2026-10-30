import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/tools/drawing_tool.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';

/// Click to place auto-sized text; drag to set the width it wraps at.
class CreateTextTool extends Tool implements DrawingTool {
  /// Screen pixels the pointer must travel sideways before a press counts as
  /// a drag; the dragged width is what matters, not the height.
  static const _dragThreshold = 6.0;

  Offset? _pressWorld;
  Rect? _dragRect;

  @override
  FeatureKind createDrawingKind() => FeatureKindText('');

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
  ) {
    final rect = _dragRect;
    if (rect == null) return;
    canvas.drawRect(
      rect,
      Paint()
        ..color = SquiggleColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = camera.screenLengthToWorldLength(1),
    );
  }

  @override
  void deactivate(EditorContext context) => _reset();

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _pressWorld = worldPosition;
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
    final press = _pressWorld;
    if (press == null) return false;
    final travelled = camera.worldLengthToScreenLength(
      (worldPosition.dx - press.dx).abs(),
    );
    if (travelled < _dragThreshold && _dragRect == null) return false;
    _dragRect = Rect.fromPoints(press, worldPosition);
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
    final rect = _dragRect;
    final fixedWidth = rect != null && rect.width > 0 ? rect.width : null;
    context.startCreateText(
      rect?.topLeft ?? _pressWorld ?? worldPosition,
      fixedWidth: fixedWidth,
    );
    _reset();
    context.resetToSelectTool();
    return true;
  }

  void _reset() {
    _pressWorld = null;
    _dragRect = null;
  }
}
