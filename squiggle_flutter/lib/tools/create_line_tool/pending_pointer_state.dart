import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/interaction_state.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool/dragging_state.dart';
import 'package:squiggle_flutter/tools/create_line_tool/placing_state.dart';

/// Distinguishes the initial click from dragging a new two-point line.
class PendingPointerState extends InteractionState<CreateLineTool> {
  PendingPointerState({required super.parent, required this.start});

  final Offset start;

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final threshold = camera.screenLengthToWorldLength(kTouchSlop);
    if ((worldPosition - start).distance <= threshold) return;

    final state = DraggingState(parent: parent, start: start);
    parent.transition(state, context);
    state.onPointerMove(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    parent.transition(
      PlacingState(parent: parent, points: [start], previewTip: worldPosition),
      context,
    );
  }

  @override
  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    parent.finish(context, const []);
    return true;
  }
}
