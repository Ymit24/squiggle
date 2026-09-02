import 'dart:ui';

import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';

class CreateFeatureTool extends Tool {
  CreateFeatureTool({required this.kind}) : _state = const _Idle();

  factory CreateFeatureTool.rect() =>
      CreateFeatureTool(kind: const FeatureKindRectangle());

  factory CreateFeatureTool.circle() =>
      CreateFeatureTool(kind: const FeatureKindCircle());

  final FeatureKind kind;
  _CreateState _state;

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
    if (_state case _Dragging(:final bounds)) {
      Feature(
        origin: bounds.topLeft,
        size: bounds.size,
        kind: kind,
      ).paint(canvas, imageRepository);
    }
  }

  @override
  void deactivate(EditorContext context) {
    _state = const _Idle();
  }

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) => true;

  @override
  bool onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    switch (_state) {
      case _Idle():
        _state = _Dragging(
          start: worldPosition,
          bounds: isAltPressed
              ? Rect.fromCenter(center: worldPosition, width: 1, height: 1)
              : Rect.fromLTWH(worldPosition.dx, worldPosition.dy, 1, 1),
        );
      case _Dragging(:final start):
        _state = _Dragging(
          start: start,
          bounds: _boundsFromDrag(
            start,
            worldPosition,
            isShiftPressed: isShiftPressed,
            isAltPressed: isAltPressed,
          ),
        );
    }
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
    if (_state case _Dragging(:final bounds)) {
      context.execute(
        AddFeatureCommand(
          Feature(origin: bounds.topLeft, size: bounds.size, kind: kind),
        ),
      );
      _state = const _Idle();
    }
    return true;
  }

  Rect _boundsFromDrag(
    Offset start,
    Offset end, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (isAltPressed && isShiftPressed) {
      return squareCenterRectFromPoints(start, end);
    }
    if (isAltPressed) {
      return centerRectFromPoints(start, end);
    }
    if (isShiftPressed) {
      return squareRectFromPoints(start, end);
    }
    return Rect.fromPoints(start, end);
  }
}

sealed class _CreateState {
  const _CreateState();
}

final class _Idle extends _CreateState {
  const _Idle();
}

final class _Dragging extends _CreateState {
  const _Dragging({required this.start, required this.bounds});

  final Offset start;
  final Rect bounds;
}
