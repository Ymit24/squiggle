import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/interaction_state.dart';

/// Screen distance from the first point within which a click closes the shape.
const _closeSnapRadius = 10.0;

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
    _updateTip(context, worldPosition, camera, isShiftPressed: isShiftPressed);
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
    _updateTip(context, worldPosition, camera, isShiftPressed: isShiftPressed);
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
    if (_closesShape(worldPosition, camera)) {
      parent.finish(context, points, isClosed: true);
      return;
    }
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
    _updateTip(context, worldPosition, camera, isShiftPressed: isShiftPressed);
  }

  @override
  void onDoubleClick(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
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

  /// Whether releasing at [worldPosition] lands on the first point of a
  /// shape with enough points to enclose an area.
  bool _closesShape(Offset worldPosition, Camera camera) =>
      points.length >= 3 &&
      (worldPosition - points.first).distance <=
          camera.screenLengthToWorldLength(_closeSnapRadius);

  void _updateTip(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
  }) {
    if (_closesShape(worldPosition, camera)) {
      parent.updatePreview(context, points, isClosed: true);
      return;
    }
    final tip = parent.constrainedPoint(
      points.last,
      worldPosition,
      isShiftPressed: isShiftPressed,
    );
    parent.updatePreview(context, [...points, tip]);
  }
}
