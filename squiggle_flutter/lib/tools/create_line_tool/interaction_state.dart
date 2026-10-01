import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool/pending_pointer_state.dart';

abstract class InteractionState {
  InteractionState({required this.parent});

  final CreateLineTool parent;

  List<Offset>? get previewPoints => null;

  /// Only placing keeps its vertices when another press starts.
  List<Offset> get pointsForNextPress => const [];

  /// Pending and placing can finish their already placed vertices.
  List<Offset>? get pointsToFinish => null;

  void onEnter(EditorContext context) {}

  void onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    parent.transition(
      PendingPointerState(
        parent: parent,
        start: worldPosition,
        placedPoints: pointsForNextPress,
      ),
      context,
    );
  }

  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    final points = pointsToFinish;
    if (points == null ||
        (event.logicalKey != LogicalKeyboardKey.enter &&
            event.logicalKey != LogicalKeyboardKey.escape)) {
      return false;
    }
    parent.finishPlacing(context, points);
    return true;
  }

  Offset constrainedPoint(
    Offset origin,
    Offset point, {
    required bool isShiftPressed,
  }) => isShiftPressed ? snapPointTo45DegreeAngle(origin, point) : point;
}
