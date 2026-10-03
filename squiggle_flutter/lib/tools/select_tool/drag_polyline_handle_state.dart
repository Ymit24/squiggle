import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/polyline_handle.dart';

class DragPolylineHandleState extends SelectInteractionState {
  DragPolylineHandleState({required super.parent, required this._handle});

  final PolylineHandle _handle;
  @override
  void onEnter(EditorContext context) {
    parent.beginTransaction(context, 'Move point', [_handle.feature]);
  }

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return EditorCursor.grabbing;
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final kind = _handle.feature.kind as FeatureKindPolyline;
    final target = _targetPosition(
      kind,
      worldPosition,
      isShiftPressed: isShiftPressed,
    );
    kind.setPoint(_handle.feature, _handle.pointIndex, target);
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

  Offset _targetPosition(
    FeatureKindPolyline kind,
    Offset worldPosition, {
    required bool isShiftPressed,
  }) {
    if (!isShiftPressed) return worldPosition;

    final points = worldPoints(_handle.feature.origin, kind.localPoints);
    final origin = _snapOrigin(points, worldPosition);
    return snapPointTo45DegreeAngle(origin, worldPosition);
  }

  Offset _snapOrigin(List<Offset> points, Offset fallback) {
    if (_handle.pointIndex > 0) return points[_handle.pointIndex - 1];
    if (points.length > 1) return points[1];
    return fallback;
  }
}
