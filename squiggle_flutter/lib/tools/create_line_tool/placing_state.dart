import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/create_line_tool/interaction_state.dart';

class PlacingState extends InteractionState {
  PlacingState({
    required super.parent,
    required this.points,
    required this.previewTip,
  });

  final List<Offset> points;
  Offset previewTip;

  @override
  List<Offset> get previewPoints => [...points, previewTip];

  @override
  List<Offset> get pointsForNextPress => points;

  @override
  List<Offset> get pointsToFinish => points;

  @override
  void onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    previewTip = constrainedPoint(
      points.last,
      worldPosition,
      isShiftPressed: isShiftPressed,
    );
  }
}
