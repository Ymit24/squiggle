import 'dart:ui';
import 'dart:math' as math;

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
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
  Feature? _hoveredTarget;
  RadialBinding? _proposedBinding;
  NodeBinding? _initialBinding;
  bool _didDrag = false;

  bool get _isEndpoint {
    final kind = _handle.feature.kind as FeatureKindPolyline;
    return _handle.pointIndex == 0 ||
        _handle.pointIndex == kind.localPoints.length - 1;
  }

  @override
  void onEnter(EditorContext context) {
    parent.beginTransaction(context, 'Move point', [_handle.feature]);
    final kind = _handle.feature.kind as FeatureKindPolyline;
    _initialBinding = _handle.pointIndex == 0
        ? kind.startBinding
        : kind.endBinding;
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
    if (!_didDrag && _isEndpoint) {
      if (_handle.pointIndex == 0) {
        kind.startBinding = null;
      } else {
        kind.endBinding = null;
      }
    }
    _didDrag = true;
    if (_isEndpoint) {
      _hoveredTarget = context.document.bindingTargetAt(pointer);
    }
    final target = _hoveredTarget;
    if (target != null) {
      final bounds = (target.kind as BindingTargetCapable).bindingBoundsFor(
        target,
      );
      final delta = pointer - bounds.center;
      final previous = _initialBinding;
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
        _proposedBinding!.pointOn(bounds) - parentOrigin,
      );
    } else {
      _proposedBinding = null;
      final parentOrigin = _handle.feature.parent?.globalOrigin ?? Offset.zero;
      kind.setPoint(
        _handle.feature,
        _handle.pointIndex,
        _targetPosition(kind, pointer, isShiftPressed: isShiftPressed) -
            parentOrigin,
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
    final bounds = (target.kind as BindingTargetCapable)
        .bindingBoundsFor(target)
        .inflate(camera.screenLengthToWorldLength(4));
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

    final points = kind.resolvedGlobalPoints(_handle.feature);
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
        final kind = _handle.feature.kind as FeatureKindPolyline;
        if (_handle.pointIndex == 0) {
          kind.startBinding = _proposedBinding;
        } else {
          kind.endBinding = _proposedBinding;
        }
      }
    }
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}
