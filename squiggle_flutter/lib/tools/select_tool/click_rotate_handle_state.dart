import 'dart:math';
import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/node.dart';

import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';

class ClickRotateHandleState extends SelectInteractionState {
  ClickRotateHandleState({required super.parent, required this.node});

  final Node node;

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final centerRelative = worldPosition - node.center();
    final angle = atan2(centerRelative.dy, centerRelative.dx);

    print("moving mouse while grabbing rotate handle! ${angle * 180 / pi}");

    node.localRotationAngle = (angle * 180 / pi) + 90;
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}
