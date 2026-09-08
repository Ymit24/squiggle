import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';

import 'box_selection_state.dart';
import 'idle_interaction_state.dart';
import 'interaction_state.dart';

class ClickCanvasState extends InteractionState {
  ClickCanvasState({required super.parent, required this._start});

  final Offset _start;

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final state = BoxSelectionState(
      parent: parent,
      start: _start,
      isShift: isShiftPressed,
    );
    parent.transition(state, context);
    state.onPointerMove(
      context,
      cursorWorldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: click canvas state up");
    if (!isShiftPressed) {
      context.selection.setSelection([]);
    }
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}
