import 'package:flutter/gestures.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/create_line_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/create_line_tool/dragging_state.dart';
import 'package:squiggle_flutter/tools/create_line_tool/placing_state.dart';

class PendingPointerState extends InteractionState {
  PendingPointerState({
    required super.parent,
    required this.start,
    required this.placedPoints,
  }) : _previewTip = start;

  final Offset start;
  final List<Offset> placedPoints;
  Offset _previewTip;
  bool _didDrag = false;

  @override
  List<Offset>? get previewPoints =>
      placedPoints.isEmpty ? null : [...placedPoints, _previewTip];

  @override
  List<Offset> get pointsToFinish => placedPoints;

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (placedPoints.isNotEmpty) {
      _previewTip = constrainedPoint(
        placedPoints.last,
        worldPosition,
        isShiftPressed: isShiftPressed,
      );
    }
    if (_didDrag) return;

    final threshold = camera.screenLengthToWorldLength(kTouchSlop);
    if ((worldPosition - start).distance <= threshold) return;

    if (placedPoints.isEmpty) {
      final state = DraggingState(parent: parent, start: start);
      parent.transition(state, context);
      state.onPointerMove(
        context,
        worldPosition,
        camera,
        isShiftPressed: isShiftPressed,
        isAltPressed: isAltPressed,
      );
    } else {
      _didDrag = true;
    }
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final point = placedPoints.isEmpty
        ? start
        : constrainedPoint(
            placedPoints.last,
            _didDrag ? worldPosition : start,
            isShiftPressed: isShiftPressed,
          );
    parent.transition(
      PlacingState(
        parent: parent,
        points: [...placedPoints, point],
        previewTip: worldPosition,
      ),
      context,
    );
  }
}
