import 'dart:ui';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';

class CreateLineTool extends Tool {
  CreateLineTool() : _state = const _Idle();

  _LineState _state;
  Feature? _previewFeature;
  Feature? _hoveredTarget;
  RadialBinding? _startBinding;
  RadialBinding? _endBinding;

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) => EditorCursor.crosshair;

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    _previewFeature?.paint(canvas, imageRepository);
    final target = _hoveredTarget;
    if (target != null) {
      final bounds = (target.kind as BindingTargetCapable)
          .bindingBoundsFor(target)
          .inflate(camera.screenLengthToWorldLength(4));
      canvas.drawRect(
        bounds,
        Paint()
          ..color = SquiggleColors.accent
          ..style = PaintingStyle.stroke
          ..strokeWidth = camera.screenLengthToWorldLength(2),
      );
    }
  }

  List<Offset>? _worldPointsForPreview() {
    return switch (_state) {
      _Dragging(:final start, :final end) => [start, end],
      _Placing(:final points, :final previewTip) =>
        previewTip != null ? [...points, previewTip] : points,
      _PendingPointer(:final placedPoints, :final previewTip) =>
        placedPoints.isNotEmpty ? [...placedPoints, previewTip] : null,
      _ => null,
    };
  }

  @override
  void deactivate(EditorContext context) => cancelInteraction(context);

  @override
  void cancelInteraction(EditorContext context) {
    _reset();
  }

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final placedPoints = switch (_state) {
      _Placing(:final points) => points,
      _ => const <Offset>[],
    };
    if (placedPoints.isEmpty) {
      _startBinding = _endpointAt(context, worldPosition).binding;
      _endBinding = null;
    } else {
      _hoveredTarget = null;
    }
    _state = _PendingPointer(
      start: worldPosition,
      placedPoints: placedPoints,
      previewTip: worldPosition,
    );
    _updatePreview(context);
    return true;
  }

  @override
  bool onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    switch (_state) {
      case _PendingPointer(:final start, :final placedPoints, :final didDrag):
        if (placedPoints.isNotEmpty) {
          final origin = placedPoints.last;
          final preview = _constrainedPoint(
            origin,
            worldPosition,
            isShiftPressed: isShiftPressed,
          );
          _state = _PendingPointer(
            start: start,
            placedPoints: placedPoints,
            previewTip: preview,
            didDrag: didDrag,
          );
        }
        if (didDrag) {
          _updatePreview(context);
          return true;
        }
        final threshold = camera.screenLengthToWorldLength(kTouchSlop);
        if ((worldPosition - start).distance <= threshold) {
          _updatePreview(context);
          return true;
        }
        if (placedPoints.isEmpty) {
          final startPoint = _startBinding == null
              ? start
              : _pointForBinding(context, _startBinding!) ?? start;
          final end = _constrainedPoint(
            startPoint,
            worldPosition,
            isShiftPressed: isShiftPressed,
          );
          _state = _Dragging(start: startPoint, end: end);
        } else {
          final origin = placedPoints.last;
          final preview = _constrainedPoint(
            origin,
            worldPosition,
            isShiftPressed: isShiftPressed,
          );
          _state = _PendingPointer(
            start: start,
            placedPoints: placedPoints,
            previewTip: preview,
            didDrag: true,
          );
        }
      case _Dragging(:final start):
        final endPosition = _constrainedPoint(
          start,
          worldPosition,
          isShiftPressed: isShiftPressed,
        );
        final endpoint = _endpointAt(context, worldPosition);
        _endBinding = endpoint.binding;
        _state = _Dragging(
          start: start,
          end: _endBinding == null ? endPosition : endpoint.point,
        );
      case _Idle() || _Placing():
        break;
    }
    _updatePreview(context);
    return true;
  }

  @override
  bool onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    switch (_state) {
      case _Dragging(:final start):
        final snappedEnd = _constrainedPoint(
          start,
          worldPosition,
          isShiftPressed: isShiftPressed,
        );
        final endpoint = _endpointAt(context, worldPosition);
        _endBinding = endpoint.binding;
        _commit(
          context,
          [start, _endBinding == null ? snappedEnd : endpoint.point],
          startBinding: _startBinding,
          endBinding: _endBinding,
        );
        _reset();
      case _PendingPointer(:final start, :final placedPoints, :final didDrag):
        if (didDrag) {
          _startBinding = null;
          final origin = placedPoints.isNotEmpty ? placedPoints.last : start;
          final point = _constrainedPoint(
            origin,
            worldPosition,
            isShiftPressed: isShiftPressed,
          );
          _state = _Placing(
            points: [...placedPoints, point],
            previewTip: worldPosition,
          );
          _updatePreview(context);
          return true;
        }
        final point = placedPoints.isEmpty
            ? start
            : _constrainedPoint(
                placedPoints.last,
                start,
                isShiftPressed: isShiftPressed,
              );
        _state = _Placing(
          points: [...placedPoints, point],
          previewTip: worldPosition,
        );
        _startBinding = null;
        _hoveredTarget = null;
      case _Idle() || _Placing():
        break;
    }
    _updatePreview(context);
    return true;
  }

  @override
  bool onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (_state is _Idle) {
      _hoveredTarget = context.document.bindingTargetAt(worldPosition);
    } else if (_state case _Placing(:final points)) {
      final origin = points.last;
      final preview = _constrainedPoint(
        origin,
        worldPosition,
        isShiftPressed: isShiftPressed,
      );
      _state = _Placing(points: points, previewTip: preview);
      _updatePreview(context);
    }
    return true;
  }

  @override
  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }

    final points = switch (_state) {
      _Placing(:final points) => points,
      _PendingPointer(:final placedPoints) => placedPoints,
      _ => null,
    };
    if (points == null) {
      return false;
    }

    _finishPlacing(context, points);
    return true;
  }

  void _finishPlacing(EditorContext context, List<Offset> points) {
    if (points.length >= 2) {
      _commit(context, points);
    }
    _reset();
  }

  void _commit(
    EditorContext context,
    List<Offset> worldPoints, {
    RadialBinding? startBinding,
    RadialBinding? endBinding,
  }) {
    final feature = _previewFeature ?? _buildFeature(context, worldPoints);
    _setFeaturePoints(feature, worldPoints);
    final kind = feature.kind as FeatureKindPolyline;
    kind.startBinding = startBinding;
    kind.endBinding = endBinding;
    context.history.run('Create feature', (transaction) {
      transaction.add(feature);
    });
  }

  void _updatePreview(EditorContext context) {
    final worldPoints = _worldPointsForPreview();
    if (worldPoints == null) return;

    final feature = _previewFeature ??= _buildFeature(context, worldPoints);
    _setFeaturePoints(feature, worldPoints);
  }

  void _setFeaturePoints(Feature feature, List<Offset> worldPoints) {
    (feature.kind as FeatureKindPolyline).setGeometry(
      feature,
      origin: worldPoints.first,
      localPoints: localPointsFromWorld(worldPoints, worldPoints.first),
    );
  }

  void _reset() {
    _state = const _Idle();
    _previewFeature = null;
    _hoveredTarget = null;
    _startBinding = null;
    _endBinding = null;
  }

  ({Offset point, RadialBinding? binding}) _endpointAt(
    EditorContext context,
    Offset pointer,
  ) {
    final target = context.document.bindingTargetAt(pointer);
    _hoveredTarget = target;
    if (target == null) return (point: pointer, binding: null);
    final bounds = (target.kind as BindingTargetCapable).bindingBoundsFor(
      target,
    );
    final delta = pointer - bounds.center;
    final binding = RadialBinding(target.id, math.atan2(delta.dy, delta.dx));
    return (point: binding.pointOn(bounds), binding: binding);
  }

  Offset? _pointForBinding(EditorContext context, RadialBinding binding) {
    final target = context.document.featureById(binding.targetId);
    if (target == null || target.kind is! BindingTargetCapable) return null;
    return binding.pointOn(
      (target.kind as BindingTargetCapable).bindingBoundsFor(target),
    );
  }

  Feature _buildFeature(EditorContext context, List<Offset> worldPoints) {
    final origin = worldPoints.first;
    final localPoints = localPointsFromWorld(worldPoints, origin);
    final kind = FeatureKindPolyline(localPoints);
    context.applyInspectorValues(kind);
    return Feature(origin: origin, size: Size.zero, kind: kind);
  }

  Offset _constrainedPoint(
    Offset origin,
    Offset point, {
    required bool isShiftPressed,
  }) {
    return isShiftPressed ? snapPointTo45DegreeAngle(origin, point) : point;
  }
}

sealed class _LineState {
  const _LineState();
}

final class _Idle extends _LineState {
  const _Idle();
}

final class _PendingPointer extends _LineState {
  const _PendingPointer({
    required this.start,
    required this.placedPoints,
    required this.previewTip,
    this.didDrag = false,
  });

  final Offset start;
  final List<Offset> placedPoints;
  final Offset previewTip;
  final bool didDrag;
}

final class _Dragging extends _LineState {
  const _Dragging({required this.start, required this.end});

  final Offset start;
  final Offset end;
}

final class _Placing extends _LineState {
  const _Placing({required this.points, this.previewTip});

  final List<Offset> points;
  final Offset? previewTip;
}
