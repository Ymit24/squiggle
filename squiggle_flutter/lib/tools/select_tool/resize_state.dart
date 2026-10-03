import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/select_tool/helpers.dart';
import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/resize_handle.dart';

class ResizeState extends SelectInteractionState {
  ResizeState({
    required super.parent,
    required this._handle,
    required Offset pointerDownWorld,
  }) : _resizeOffset =
           pointerDownWorld -
           _referenceFor(_handle.handle, _handle.node.localBounds());

  final ResizeHandle _handle;
  final Offset _resizeOffset;
  late final Rect _initialBounds = _handle.node.localBounds();
  bool _detachedBindings = false;

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
    final newBounds = getNewBounds(
      worldPosition - _resizeOffset,
      lockAspectRatio: isShiftPressed,
      symmetric: isAltPressed,
    );
    if (!_detachedBindings && newBounds != _initialBounds) {
      final node = _handle.node;
      if (node is Feature && node.kind is FeatureKindPolyline) {
        (node.kind as FeatureKindPolyline).detachBindings(node);
      }
      _detachedBindings = true;
    }
    _handle.node.resize(newBounds);
  }

  Rect getNewBounds(
    Offset worldPosition, {
    bool lockAspectRatio = false,
    bool symmetric = false,
  }) => symmetric
      ? _symmetricBounds(worldPosition, lockAspectRatio)
      : _asymmetricBounds(worldPosition, lockAspectRatio);

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

  bool get _resizesHorizontally =>
      _handle.handle == SelectionResizeHandle.left ||
      _handle.handle == SelectionResizeHandle.right;

  bool get _resizesVertically =>
      _handle.handle == SelectionResizeHandle.top ||
      _handle.handle == SelectionResizeHandle.bottom;

  Rect _asymmetricBounds(Offset worldPosition, bool lockAspectRatio) =>
      lockAspectRatio
      ? _aspectLockedAsymmetricBounds(worldPosition)
      : Rect.fromPoints(
          Offset(
            _movesLeft ? worldPosition.dx : _initialBounds.left,
            _movesTop ? worldPosition.dy : _initialBounds.top,
          ),
          Offset(
            _movesRight ? worldPosition.dx : _initialBounds.right,
            _movesBottom ? worldPosition.dy : _initialBounds.bottom,
          ),
        );

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

  static Offset _referenceFor(SelectionResizeHandle handle, Rect bounds) {
    return switch (handle) {
      SelectionResizeHandle.topLeft ||
      SelectionResizeHandle.top ||
      SelectionResizeHandle.left => bounds.topLeft,
      SelectionResizeHandle.topRight => bounds.topRight,
      SelectionResizeHandle.right ||
      SelectionResizeHandle.bottomRight ||
      SelectionResizeHandle.bottom => bounds.bottomRight,
      SelectionResizeHandle.bottomLeft => bounds.bottomLeft,
    };
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
}
