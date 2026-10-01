import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/binding_candidate.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/polyline_handle.dart';

class DragPolylineHandleState extends SelectInteractionState {
  DragPolylineHandleState({
    required super.parent,
    required this._handle,
    required this.pointerDownWorld,
  });

  final PolylineHandle _handle;
  final Offset pointerDownWorld;
  BindingCandidate? _candidate;
  bool _didDrag = false;

  FeatureKindPolyline get _kind => _handle.feature.kind as FeatureKindPolyline;
  bool get _isEndpoint =>
      _handle.pointIndex == 0 ||
      _handle.pointIndex == _kind.localPoints.length - 1;
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
    _updateDrag(context, worldPosition, camera, isShiftPressed: isShiftPressed);
  }

  void _updateDrag(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
  }) {
    if (!_didDrag &&
        (worldPosition - pointerDownWorld).distance <
            camera.screenLengthToWorldLength(2)) {
      return;
    }
    _didDrag = true;
    final kind = _kind;
    if (_isEndpoint) {
      if (_handle.pointIndex == 0) {
        kind.startBinding = null;
      } else {
        kind.endBinding = null;
      }
      _candidate = BindingCandidate.at(context.document, worldPosition);
    }
    final target =
        _candidate?.point ??
        _targetPosition(kind, worldPosition, isShiftPressed: isShiftPressed);
    final parentOrigin = _handle.feature.parent?.globalOrigin ?? Offset.zero;
    kind.setPoint(_handle.feature, _handle.pointIndex, target - parentOrigin);
  }

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    _candidate?.paint(canvas, camera);
  }

  Offset _targetPosition(
    FeatureKindPolyline kind,
    Offset worldPosition, {
    required bool isShiftPressed,
  }) {
    if (!isShiftPressed) return worldPosition;

    final points = kind.resolvedGlobalPoints(_handle.feature);
    final origin = _snapOrigin(points, worldPosition);
    return snapPointTo45DegreeAngle(origin, worldPosition);
  }

  Offset _snapOrigin(List<Offset> points, Offset fallback) {
    if (_handle.pointIndex > 0) return points[_handle.pointIndex - 1];
    if (points.length > 1) return points[1];
    return fallback;
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _updateDrag(context, worldPosition, camera, isShiftPressed: isShiftPressed);
    if (_didDrag && _isEndpoint) {
      if (_handle.pointIndex == 0) {
        _kind.startBinding = _candidate?.binding;
      } else {
        _kind.endBinding = _candidate?.binding;
      }
    }
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}
