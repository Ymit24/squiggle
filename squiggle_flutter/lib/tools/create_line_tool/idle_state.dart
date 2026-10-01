import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/create_line_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/create_line_tool/pending_pointer_state.dart';

class IdleState extends InteractionState {
  IdleState({required super.parent});

  @override
  void onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    parent.transition(
      PendingPointerState(parent: parent, start: worldPosition),
      context,
    );
  }
}
