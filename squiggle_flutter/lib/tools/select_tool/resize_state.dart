import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/select_tool/helpers.dart';
import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/resize_handle.dart';

class ResizeState extends SelectInteractionState {
  ResizeState({
    required super.parent,
    required ResizeHandle handle,
    required Offset pointerDownWorld,
  }) : _handle = handle,
       _initialBounds = handle.node.localBounds(),
       _initialCenter = handle.node.localBounds().center,
       _rotationDegrees = handle.node.localRotationAngle,
       _resizeOffset =
           _toUnrotated(
             handle.node.localBounds().center,
             pointerDownWorld,
             handle.node.localRotationAngle,
           ) -
           _handlePoint(handle.handle, handle.node.localBounds()),
       _fixedAnchor = _oppositeAnchor(
         handle.handle,
         handle.node.localBounds(),
       );

  final ResizeHandle _handle;
  final Rect _initialBounds;
  final Offset _initialCenter;
  final double _rotationDegrees;
  final Offset _resizeOffset;
  final Offset _fixedAnchor;

  bool get _resizesHorizontally =>
      _handle.handle == SelectionResizeHandle.left ||
      _handle.handle == SelectionResizeHandle.right;

  bool get _resizesVertically =>
      _handle.handle == SelectionResizeHandle.top ||
      _handle.handle == SelectionResizeHandle.bottom;

  bool get _movesLeft => switch (_handle.handle) {
    SelectionResizeHandle.topLeft ||
    SelectionResizeHandle.left ||
    SelectionResizeHandle.bottomLeft => true,
    _ => false,
  };

  bool get _movesRight => switch (_handle.handle) {
    SelectionResizeHandle.topRight ||
    SelectionResizeHandle.right ||
    SelectionResizeHandle.bottomRight => true,
    _ => false,
  };

  bool get _movesTop => switch (_handle.handle) {
    SelectionResizeHandle.topLeft ||
    SelectionResizeHandle.top ||
    SelectionResizeHandle.topRight => true,
    _ => false,
  };

  bool get _movesBottom => switch (_handle.handle) {
    SelectionResizeHandle.bottomLeft ||
    SelectionResizeHandle.bottom ||
    SelectionResizeHandle.bottomRight => true,
    _ => false,
  };

  @override
  void onEnter(EditorContext context) {
    parent.beginTransaction(context, 'Resize', [_handle.node]);
  }

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return cursorForResizeHandle(_handle.handle);
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final rotatedPoint =
        _toUnrotated(_initialCenter, worldPosition, _rotationDegrees) -
        _resizeOffset;
    final newBounds = getNewBounds(
      rotatedPoint,
      lockAspectRatio: isShiftPressed,
      symmetric: isAltPressed,
    );
    _handle.node.resize(
      isAltPressed ? newBounds : _boundsKeepingAnchorFixed(newBounds),
    );
  }

  Rect getNewBounds(
    Offset worldPosition, {
    bool lockAspectRatio = false,
    bool symmetric = false,
  }) {
    if (symmetric) {
      return _symmetricBounds(worldPosition, lockAspectRatio);
    }
    return _asymmetricBounds(worldPosition, lockAspectRatio);
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

  Rect _symmetricBounds(Offset worldPosition, bool lockAspectRatio) {
    final center = _initialBounds.center;
    if (lockAspectRatio) {
      final isCorner = switch (_handle.handle) {
        SelectionResizeHandle.topLeft ||
        SelectionResizeHandle.topRight ||
        SelectionResizeHandle.bottomLeft ||
        SelectionResizeHandle.bottomRight => true,
        _ => false,
      };
      return symmetricRectWithAspectRatio(
        center,
        worldPosition,
        _initialBounds.width / _initialBounds.height,
        resizeHorizontal: isCorner || _resizesHorizontally,
        resizeVertical: isCorner || _resizesVertically,
      );
    }

    return switch (_handle.handle) {
      SelectionResizeHandle.topLeft ||
      SelectionResizeHandle.topRight ||
      SelectionResizeHandle.bottomLeft ||
      SelectionResizeHandle.bottomRight => Rect.fromCenter(
        center: center,
        width: (worldPosition.dx - center.dx).abs() * 2,
        height: (worldPosition.dy - center.dy).abs() * 2,
      ),
      SelectionResizeHandle.top ||
      SelectionResizeHandle.bottom => Rect.fromCenter(
        center: center,
        width: _initialBounds.width,
        height: (worldPosition.dy - center.dy).abs() * 2,
      ),
      SelectionResizeHandle.left ||
      SelectionResizeHandle.right => Rect.fromCenter(
        center: center,
        width: (worldPosition.dx - center.dx).abs() * 2,
        height: _initialBounds.height,
      ),
    };
  }

  Rect _asymmetricBounds(Offset worldPosition, bool lockAspectRatio) {
    if (lockAspectRatio) {
      return _aspectLockedAsymmetricBounds(worldPosition);
    }
    return Rect.fromPoints(
      Offset(
        _movesLeft ? worldPosition.dx : _initialBounds.left,
        _movesTop ? worldPosition.dy : _initialBounds.top,
      ),
      Offset(
        _movesRight ? worldPosition.dx : _initialBounds.right,
        _movesBottom ? worldPosition.dy : _initialBounds.bottom,
      ),
    );
  }

  Rect _aspectLockedAsymmetricBounds(Offset worldPosition) {
    final ratio = _initialBounds.width / _initialBounds.height;
    return switch (_handle.handle) {
      SelectionResizeHandle.topLeft => rectFromAnchorWithAspectRatio(
        _initialBounds.bottomRight,
        worldPosition,
        ratio,
      ),
      SelectionResizeHandle.topRight => rectFromAnchorWithAspectRatio(
        _initialBounds.bottomLeft,
        worldPosition,
        ratio,
      ),
      SelectionResizeHandle.bottomRight => rectFromAnchorWithAspectRatio(
        _initialBounds.topLeft,
        worldPosition,
        ratio,
      ),
      SelectionResizeHandle.bottomLeft => rectFromAnchorWithAspectRatio(
        _initialBounds.topRight,
        worldPosition,
        ratio,
      ),
      SelectionResizeHandle.top ||
      SelectionResizeHandle.right ||
      SelectionResizeHandle.bottom ||
      SelectionResizeHandle.left => edgeResizeWithAspectRatio(
        _initialBounds,
        worldPosition,
        resizeTop: _movesTop,
        resizeBottom: _movesBottom,
        resizeLeft: _movesLeft,
        resizeRight: _movesRight,
        aspectRatio: ratio,
      ),
    };
  }

  Rect _boundsKeepingAnchorFixed(Rect bounds) {
    final oldAnchor =
        _initialCenter +
        rotatePoint(
          Offset.zero,
          _fixedAnchor - _initialCenter,
          _rotationDegrees,
        );
    final newCenter = bounds.center;
    final newAnchor =
        newCenter +
        rotatePoint(Offset.zero, _fixedAnchor - newCenter, _rotationDegrees);
    return bounds.shift(oldAnchor - newAnchor);
  }

  static Offset _toUnrotated(Offset center, Offset point, double degrees) =>
      rotatePoint(center, point, -degrees) + center;

  static Offset _handlePoint(SelectionResizeHandle handle, Rect bounds) {
    return switch (handle) {
      SelectionResizeHandle.topLeft => bounds.topLeft,
      SelectionResizeHandle.top => bounds.topCenter,
      SelectionResizeHandle.topRight => bounds.topRight,
      SelectionResizeHandle.right => bounds.centerRight,
      SelectionResizeHandle.bottomRight => bounds.bottomRight,
      SelectionResizeHandle.bottom => bounds.bottomCenter,
      SelectionResizeHandle.bottomLeft => bounds.bottomLeft,
      SelectionResizeHandle.left => bounds.centerLeft,
    };
  }

  static Offset _oppositeAnchor(SelectionResizeHandle handle, Rect bounds) {
    return switch (handle) {
      SelectionResizeHandle.topLeft => bounds.bottomRight,
      SelectionResizeHandle.top => bounds.bottomCenter,
      SelectionResizeHandle.topRight => bounds.bottomLeft,
      SelectionResizeHandle.right => bounds.centerLeft,
      SelectionResizeHandle.bottomRight => bounds.topLeft,
      SelectionResizeHandle.bottom => bounds.topCenter,
      SelectionResizeHandle.bottomLeft => bounds.topRight,
      SelectionResizeHandle.left => bounds.centerRight,
    };
  }
}
