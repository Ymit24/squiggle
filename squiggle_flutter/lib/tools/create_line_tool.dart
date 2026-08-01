import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/commands/commands.dart';
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

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) =>
      EditorCursor.crosshair;

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    final worldPoints = _worldPointsForPaint();
    if (worldPoints == null) {
      return;
    }
    _buildFeature(worldPoints).paint(canvas, imageRepository);
  }

  List<Offset>? _worldPointsForPaint() {
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
  void deactivate(EditorContext context) {
    _state = const _Idle();
  }

  @override
  void onPointerDown(
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
    _state = _PendingPointer(
      start: worldPosition,
      placedPoints: placedPoints,
      previewTip: worldPosition,
    );
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    switch (_state) {
      case _PendingPointer(
        :final start,
        :final placedPoints,
        :final didDrag,
      ):
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
          return;
        }
        final threshold = camera.screenLengthToWorldLength(kTouchSlop);
        if ((worldPosition - start).distance <= threshold) {
          return;
        }
        if (placedPoints.isEmpty) {
          final end = _constrainedPoint(
            start,
            worldPosition,
            isShiftPressed: isShiftPressed,
          );
          _state = _Dragging(start: start, end: end);
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
        final end = _constrainedPoint(
          start,
          worldPosition,
          isShiftPressed: isShiftPressed,
        );
        _state = _Dragging(start: start, end: end);
      case _Idle() || _Placing():
        break;
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
    switch (_state) {
      case _Dragging(:final start):
        final snappedEnd = _constrainedPoint(
          start,
          worldPosition,
          isShiftPressed: isShiftPressed,
        );
        _commit(context, [start, snappedEnd]);
        _state = const _Idle();
      case _PendingPointer(:final start, :final placedPoints, :final didDrag):
        if (didDrag) {
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
          return;
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
      case _Idle() || _Placing():
        break;
    }
  }

  @override
  void onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (_state case _Placing(:final points)) {
      final origin = points.last;
      final preview = _constrainedPoint(
        origin,
        worldPosition,
        isShiftPressed: isShiftPressed,
      );
      _state = _Placing(points: points, previewTip: preview);
    }
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
    _state = const _Idle();
  }

  void _commit(EditorContext context, List<Offset> worldPoints) {
    context.execute(AddFeatureCommand(_buildFeature(worldPoints)));
  }

  Feature _buildFeature(List<Offset> worldPoints) {
    final origin = worldPoints.first;
    final localPoints = localPointsFromWorld(worldPoints, origin);
    return Feature(
      origin: origin,
      size: Size.zero,
      kind: const FeatureKindPolyline(
        [],
        fillColor: SquiggleColors.accent,
      ).copyWith(localPoints: localPoints),
    );
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
