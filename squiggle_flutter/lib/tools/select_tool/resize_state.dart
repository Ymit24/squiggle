import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'helpers.dart';
import 'idle_interaction_state.dart';
import 'interaction_state.dart';
import 'resize_handle.dart';

class ResizeState extends InteractionState {
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
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final newBounds = getNewBounds(
      cursorWorldPosition - _resizeOffset,
      lockAspectRatio: isShiftPressed,
      symmetric: isAltPressed,
    );
    _handle.node.resize(newBounds);
  }

  Rect getNewBounds(
    Offset cursorWorldPosition, {
    bool lockAspectRatio = false,
    bool symmetric = false,
  }) => symmetric
      ? _symmetricBounds(cursorWorldPosition, lockAspectRatio)
      : _asymmetricBounds(cursorWorldPosition, lockAspectRatio);

  Rect _symmetricBounds(Offset cursorWorldPosition, bool lockAspectRatio) {
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
        cursorWorldPosition,
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
        width: (cursorWorldPosition.dx - center.dx).abs() * 2,
        height: (cursorWorldPosition.dy - center.dy).abs() * 2,
      ),
      SelectionResizeHandle.top ||
      SelectionResizeHandle.bottom => Rect.fromCenter(
        center: center,
        width: _initialBounds.width,
        height: (cursorWorldPosition.dy - center.dy).abs() * 2,
      ),
      SelectionResizeHandle.left ||
      SelectionResizeHandle.right => Rect.fromCenter(
        center: center,
        width: (cursorWorldPosition.dx - center.dx).abs() * 2,
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

  Rect _asymmetricBounds(Offset cursorWorldPosition, bool lockAspectRatio) =>
      lockAspectRatio
      ? _aspectLockedAsymmetricBounds(cursorWorldPosition)
      : Rect.fromLTRB(
          _movesLeft ? cursorWorldPosition.dx : _initialBounds.left,
          _movesTop ? cursorWorldPosition.dy : _initialBounds.top,
          _movesRight ? cursorWorldPosition.dx : _initialBounds.right,
          _movesBottom ? cursorWorldPosition.dy : _initialBounds.bottom,
        );

  Rect _aspectLockedAsymmetricBounds(Offset cursorWorldPosition) {
    final ratio = _initialBounds.width / _initialBounds.height;
    return switch (_handle.handle) {
      SelectionResizeHandle.topLeft => rectFromAnchorWithAspectRatio(
        _initialBounds.bottomRight,
        cursorWorldPosition,
        ratio,
      ),
      SelectionResizeHandle.topRight => rectFromAnchorWithAspectRatio(
        _initialBounds.bottomLeft,
        cursorWorldPosition,
        ratio,
      ),
      SelectionResizeHandle.bottomRight => rectFromAnchorWithAspectRatio(
        _initialBounds.topLeft,
        cursorWorldPosition,
        ratio,
      ),
      SelectionResizeHandle.bottomLeft => rectFromAnchorWithAspectRatio(
        _initialBounds.topRight,
        cursorWorldPosition,
        ratio,
      ),
      SelectionResizeHandle.top ||
      SelectionResizeHandle.right ||
      SelectionResizeHandle.bottom ||
      SelectionResizeHandle.left => edgeResizeWithAspectRatio(
        _initialBounds,
        cursorWorldPosition,
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
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}
