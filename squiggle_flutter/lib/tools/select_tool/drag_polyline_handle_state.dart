import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_binding.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/bind_target.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/polyline_handle.dart';
import 'package:squiggle_flutter/tools/select_tool/selection_painter.dart';

class DragPolylineHandleState extends SelectInteractionState {
  DragPolylineHandleState({required super.parent, required this._handle});

  final PolylineHandle _handle;

  /// The node the dragged end currently binds to.
  Node? _bindTarget;

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
    _bindDraggedEnd(context, kind, target);
    kind.setPoint(_handle.feature, _handle.pointIndex, target);
  }

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    if (_bindTarget case final target?) {
      SelectionPainter.paintBindTarget(canvas, camera, target);
    }
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

    final points = kind.resolvedPoints(_handle.feature);
    final origin = _snapOrigin(points, worldPosition);
    return snapPointTo45DegreeAngle(origin, worldPosition);
  }

  Offset _snapOrigin(List<Offset> points, Offset fallback) {
    if (_handle.pointIndex > 0) return points[_handle.pointIndex - 1];
    if (points.length > 1) return points[1];
    return fallback;
  }

  /// Ends bind to whatever they are dropped on; interior points never bind.
  void _bindDraggedEnd(
    EditorContext context,
    FeatureKindPolyline kind,
    Offset worldPosition,
  ) {
    final index = _handle.pointIndex;
    final isStart = index == 0;
    if (kind.localPoints.length < 2 ||
        (!isStart && index != kind.localPoints.length - 1)) {
      return;
    }
    final otherEnd = isStart ? kind.endBinding : kind.startBinding;
    _bindTarget = bindTargetAt(
      context,
      worldPosition,
      line: _handle.feature,
      exclude: otherEnd?.targetId,
    );
    final binding = switch (_bindTarget) {
      final target? => NodeBinding(target.id),
      null => null,
    };
    if (isStart) {
      kind.startBinding = binding;
    } else {
      kind.endBinding = binding;
    }
  }
}
