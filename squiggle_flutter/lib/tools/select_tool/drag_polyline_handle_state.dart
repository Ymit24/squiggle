import 'dart:ui';
import 'dart:math' as math;

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/polyline_handle.dart';

class DragPolylineHandleState extends InteractionState {
  DragPolylineHandleState({
    required super.parent,
    required this._handle,
    required this.pointerDownWorld,
  });

  final PolylineHandle _handle;
  final Offset pointerDownWorld;
  Node? _hoveredTarget;
  RadialBinding? _proposedBinding;
  bool _didDrag = false;

  bool get _isEndpoint {
    final kind = _handle.feature.kind as FeatureKindPolyline;
    return _handle.pointIndex == 0 ||
        _handle.pointIndex == kind.localPoints.length - 1;
  }

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
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _updateDrag(context, cursorWorldPosition, isShiftPressed: isShiftPressed);
  }

  void _updateDrag(
    EditorContext context,
    Offset pointer, {
    required bool isShiftPressed,
  }) {
    if (!_didDrag &&
        (pointer - pointerDownWorld).distance <
            context.camera.screenLengthToWorldLength(2)) {
      return;
    }
    final kind = _handle.feature.kind as FeatureKindPolyline;
    _didDrag = true;
    if (_isEndpoint) {
      _hoveredTarget = context.document.bindingTargetAt(
        pointer,
        source: _handle.feature,
      );
    }
    final target = _hoveredTarget;
    if (target != null) {
      final delta = pointer - target.globalBounds().center;
      final previous = _handle.pointIndex == 0
          ? kind.startBinding
          : kind.endBinding;
      final angle =
          delta.distanceSquared < 1e-8 &&
              previous is RadialBinding &&
              previous.targetId == target.id
          ? previous.angle
          : math.atan2(delta.dy, delta.dx);
      _proposedBinding = RadialBinding(target.id, angle);
      final parentOrigin = _handle.feature.parent?.globalOrigin ?? Offset.zero;
      kind.setPoint(
        _handle.feature,
        _handle.pointIndex,
        _proposedBinding!.pointOn(target.globalBounds()) - parentOrigin,
      );
    } else {
      _proposedBinding = null;
      kind.setPoint(
        _handle.feature,
        _handle.pointIndex,
        _targetPosition(kind, pointer, isShiftPressed: isShiftPressed),
      );
    }
  }

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    final target = _hoveredTarget;
    if (target == null) return;
    final bounds = target.globalBounds().inflate(
      camera.screenLengthToWorldLength(4),
    );
    final outline = Paint()
      ..color = SquiggleColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = camera.screenLengthToWorldLength(2);
    canvas.drawRect(bounds, outline);
  }

  Offset _targetPosition(
    FeatureKindPolyline kind,
    Offset cursorWorldPosition, {
    required bool isShiftPressed,
  }) {
    if (!isShiftPressed) return cursorWorldPosition;

    final points = worldPoints(_handle.feature.origin, kind.localPoints);
    final origin = _snapOrigin(points, cursorWorldPosition);
    return snapPointTo45DegreeAngle(origin, cursorWorldPosition);
  }

  Offset _snapOrigin(List<Offset> points, Offset fallback) {
    if (_handle.pointIndex > 0) return points[_handle.pointIndex - 1];
    if (points.length > 1) return points[1];
    return fallback;
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _updateDrag(context, cursorWorldPosition, isShiftPressed: isShiftPressed);
    if (_didDrag) {
      if (_isEndpoint) {
        context.document.setFeatureBinding(
          _handle.feature,
          start: _handle.pointIndex == 0,
          binding: _proposedBinding,
        );
      }
    }
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}
