import 'dart:ui';

import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/select_tool/helpers.dart';
import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/resize_handle.dart';
import 'package:squiggle_flutter/tools/select_tool/resize_policy.dart';
import 'package:squiggle_flutter/tools/select_tool/selection_resize_handle.dart';

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
  late final ResizePolicy _policy = ResizePolicy.of(_handle.node);

  /// The node as it was before the drag. Every move restores it first, so a
  /// resize is always computed from the initial state and cannot compound.
  late final data.Node _snapshot;

  bool get _movesLeft => _handle.handle.movesLeft;
  bool get _movesRight => _handle.handle.movesRight;
  bool get _movesTop => _handle.handle.movesTop;
  bool get _movesBottom => _handle.handle.movesBottom;

  @override
  void onEnter(EditorContext context) {
    _snapshot = _handle.node.toDataModel();
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
      lockAspectRatio:
          isShiftPressed ||
          (_policy.lockCornerAspect && _handle.handle.isCorner),
      symmetric: isAltPressed,
    );
    _handle.node
      ..restoreFromDataModel(_snapshot)
      ..resize(newBounds);
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
      return symmetricRectWithAspectRatio(
        center,
        worldPosition,
        _initialBounds.width / _initialBounds.height,
        resizeHorizontal: _movesLeft || _movesRight,
        resizeVertical: _movesTop || _movesBottom,
      );
    }

    if (_handle.handle.isCorner) {
      return Rect.fromCenter(
        center: center,
        width: (worldPosition.dx - center.dx).abs() * 2,
        height: (worldPosition.dy - center.dy).abs() * 2,
      );
    }
    return switch (_handle.handle) {
      SelectionResizeHandle.top ||
      SelectionResizeHandle.bottom => Rect.fromCenter(
        center: center,
        width: _initialBounds.width,
        height: (worldPosition.dy - center.dy).abs() * 2,
      ),
      _ => Rect.fromCenter(
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
}
