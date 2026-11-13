import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool/pending_pointer_state.dart';
import 'package:squiggle_flutter/tools/interaction_state.dart';
import 'package:squiggle_flutter/tools/pointer_modifiers.dart';

class IdleState extends InteractionState<CreateLineTool> {
  IdleState({required super.parent});

  @override
  void onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required PointerModifiers modifiers,
  }) {
    parent.transition(
      PendingPointerState(parent: parent, start: worldPosition),
      context,
    );
  }

  @override
  void onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required PointerModifiers modifiers,
  }) {
    parent.ends.hover(context, worldPosition);
  }
}
