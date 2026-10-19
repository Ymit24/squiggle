import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/interaction_state.dart';

class PlacingState extends InteractionState<CreateLineTool> {
  PlacingState({
    required super.parent,
    required this.points,
    required this.previewTip,
  });

  final List<Offset> points;
  final Offset previewTip;
  bool _isPointerDown = false;

  @override
  void onEnter(EditorContext context) {
    parent.updatePreview(context, [...points, previewTip]);
  }

  @override
  void onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _isPointerDown = true;
    parent.updatePreview(context, [...points, worldPosition]);
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (!_isPointerDown) return;
    _updateTip(context, worldPosition, isShiftPressed: isShiftPressed);
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (!_isPointerDown) return;
    _isPointerDown = false;
    points.add(
      parent.constrainedPoint(
        points.last,
        worldPosition,
        isShiftPressed: isShiftPressed,
      ),
    );
    parent.updatePreview(context, [...points, worldPosition]);
  }

  @override
  void onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _updateTip(context, worldPosition, isShiftPressed: isShiftPressed);
  }

  @override
  void onDoubleClick(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    // The second click's pointer-up already added a point at (nearly) the same
    // spot as the first click's; drop it so the final point isn't duplicated.
    if (points.length > 1 &&
        (points.last - points[points.length - 2]).distance * camera.zoom <
            10) {
      points.removeLast();
    }
    parent.finish(context, points);
  }

  @override
  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    parent.finish(context, points);
    return true;
  }

  void _updateTip(
    EditorContext context,
    Offset worldPosition, {
    required bool isShiftPressed,
  }) {
    final tip = parent.constrainedPoint(
      points.last,
      worldPosition,
      isShiftPressed: isShiftPressed,
    );
    parent.updatePreview(context, [...points, tip]);
  }
}
