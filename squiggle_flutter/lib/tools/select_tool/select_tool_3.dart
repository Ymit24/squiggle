import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/selection_painter.dart';
import 'package:squiggle_flutter/tools/tool.dart';

HitTarget getTargetUnderCursor(EditorContext context, Offset worldPosition) {
  if (context.selection.selectedFeatures.length == 1) {
    final feature = context.document.featureById(
      context.selection.selectedFeatures.first,
    );
    if (feature != null) {
      final polyHandle = PolylineHandleUtil.hitTest(
        feature,
        worldPosition,
        context.camera,
      );
      if (polyHandle != null) {
        return PolylineHandleTarget(handle: polyHandle);
      }
      final handle = ResizeHandleUtil.hitTest(
        feature,
        worldPosition,
        context.camera,
      );
      if (handle != null) {
        return ResizeHandleTarget(handle: handle);
      }
    }
  }
  final feature = context.document.featureAtPoint(worldPosition);
  if (feature != null) {
    return NodeTarget(node: feature);
  }

  return CanvasTarget();
}

EditorCursor cursorForResizeHandle(SelectionResizeHandle handle) {
  return switch (handle) {
    SelectionResizeHandle.topLeft => EditorCursor.resizeUpLeft,
    SelectionResizeHandle.top => EditorCursor.resizeUp,
    SelectionResizeHandle.topRight => EditorCursor.resizeUpRight,
    SelectionResizeHandle.right => EditorCursor.resizeRight,
    SelectionResizeHandle.bottomRight => EditorCursor.resizeDownRight,
    SelectionResizeHandle.bottom => EditorCursor.resizeDown,
    SelectionResizeHandle.bottomLeft => EditorCursor.resizeDownLeft,
    SelectionResizeHandle.left => EditorCursor.resizeLeft,
  };
}

class SelectTool3 extends Tool {
  late InteractionState _activeInteractionState = IdleInteractionState(
    parent: this,
  );

  void transition(InteractionState state, EditorContext context) {
    _activeInteractionState = state;
    _activeInteractionState.onEnter(context);
  }

  @override
  void deactivate(EditorContext context) {
    _activeInteractionState = IdleInteractionState(parent: this);
    context.selection.clearSelection();
  }

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _activeInteractionState.onPointerDown(
      context,
      getTargetUnderCursor(context, worldPosition),
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );

    // TODO: Update how change detection works to not be bool response based.
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
    _activeInteractionState.onPointerMove(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    // TODO: Update how change detection works to not be bool response based.
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
    _activeInteractionState.onPointerUp(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    // TODO: Update how change detection works to not be bool response based.
    return true;
  }

  @override
  bool onDoubleClick(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    _activeInteractionState.onDoubleClick(
      context,
      getTargetUnderCursor(context, worldPosition),
      worldPosition,
      camera,
    );
    return true;
  }

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    _activeInteractionState.paint(canvas, camera, context, imageRepository);

    SelectionPainter.paintSelectedFeatureBoxes(canvas, camera, context);
    SelectionPainter.paintSelectedPolylineHandles(canvas, camera, context);
  }

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return _activeInteractionState.resolveCursor(
      context,
      worldPosition,
      camera,
    );
  }
}

abstract class InteractionState {
  final SelectTool3 parent;

  InteractionState({required this.parent});

  void onEnter(EditorContext context) {}

  void onPointerDown(
    EditorContext context,
    HitTarget target,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onDoubleClick(
    EditorContext context,
    HitTarget target,
    Offset worldPosition,
    Camera camera,
  ) {}

  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {}

  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return EditorCursor.basic;
  }
}

class HitTarget {}

class CanvasTarget extends HitTarget {}

class NodeTarget extends HitTarget {
  final Node node;

  NodeTarget({required this.node});
}

class ResizeHandleTarget extends HitTarget {
  final ResizeHandle handle;

  ResizeHandleTarget({required this.handle});
}

class PolylineHandleTarget extends HitTarget {
  final PolylineHandle handle;

  PolylineHandleTarget({required this.handle});
}

class IdleInteractionState extends InteractionState {
  IdleInteractionState({required super.parent});

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return switch (getTargetUnderCursor(context, worldPosition)) {
      ResizeHandleTarget(handle: final handle) => cursorForResizeHandle(
        handle.handle,
      ),
      PolylineHandleTarget() => EditorCursor.grab,
      NodeTarget() => EditorCursor.grab,
      CanvasTarget() => EditorCursor.basic,
      _ => EditorCursor.basic,
    };
  }

  @override
  void onPointerDown(
    EditorContext context,
    HitTarget target,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: idle state down. Hit target: $target");
    switch (target) {
      case ResizeHandleTarget(handle: var handle):
        print("D: Clicked on handle: ${target.handle}");
        parent.transition(
          ResizeState(
            parent: parent,
            handle: handle,
            pointerDownWorld: cursorWorldPosition,
          ),
          context,
        );
        break;
      case PolylineHandleTarget(handle: var handle):
        print("D: Clicked on polyline handle: ${target.handle}");
        parent.transition(
          DragPolylineHandleState(parent: parent, handle: handle),
          context,
        );
        break;
      case NodeTarget(node: var chaseNode):
        final selectedNodes = context.selection.selectedFeatures.map(
          (id) => context.document.featureById(id),
        );
        if (selectedNodes.any((f) => f == null)) {
          // TODO: Is this possible? What to do?
          return;
        }
        parent.transition(
          ClickNodeState(
            parent: parent,
            start: cursorWorldPosition,
            chase: chaseNode,
            selectedNodes: selectedNodes.map((f) => f!).toList(),
            isShiftPressed: isShiftPressed,
          ),
          context,
        );
        break;
      case CanvasTarget():
        parent.transition(
          ClickCanvasState(parent: parent, start: cursorWorldPosition),
          context,
        );
        break;
    }
  }

  @override
  void onDoubleClick(
    EditorContext context,
    HitTarget target,
    Offset worldPosition,
    Camera camera,
  ) {
    print("D: Idle double click on target: $target!");
    if (target case NodeTarget(
      node: final Feature feature,
    ) when feature.kind is FeatureKindText) {
      final text = feature.kind as FeatureKindText;
      context.selection.setSelection([feature.id]);
      context.startTextEdit(
        EditTextEditSession(
          featureId: feature.id,
          initialContents: text.contents,
          canvasLocalBounds: camera.worldToScreenBounds(feature.bounds()),
        ),
      );
      return;
    }
  }
}

class DragPolylineHandleState extends InteractionState {
  DragPolylineHandleState({required super.parent, required this._handle});

  final PolylineHandle _handle;
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
    final kind = _handle.feature.kind as FeatureKindPolyline;
    final target = _targetPosition(
      kind,
      cursorWorldPosition,
      isShiftPressed: isShiftPressed,
    );
    kind.setPoint(_handle.feature, _handle.pointIndex, target);
  }

  Offset _targetPosition(
    FeatureKindPolyline kind,
    Offset cursorWorldPosition, {
    required bool isShiftPressed,
  }) {
    if (!isShiftPressed) return cursorWorldPosition;

    final points = worldPoints(_handle.feature.origin, kind.localPoints);
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
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}

class ResizeState extends InteractionState {
  ResizeState({
    required super.parent,
    required this._handle,
    required Offset pointerDownWorld,
  }) : _resizeOffset =
           pointerDownWorld -
           _referenceFor(_handle.handle, _handle.node.bounds());

  final ResizeHandle _handle;
  final Offset _resizeOffset;
  late final Rect _initialBounds = _handle.node.bounds();

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
    print("D: on pointer move");

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

class BoxSelectionState extends InteractionState {
  BoxSelectionState({
    required super.parent,
    required this._start,
    required this.isShift,
  }) {
    _current = _start;
  }

  final Offset _start;
  late Offset _current;
  final bool isShift;

  @override
  void onEnter(EditorContext context) {
    if (isShift) {
      return;
    }
    context.selection.setSelection([]);
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: box state move");
    _current = cursorWorldPosition;

    final selectionBounds = Rect.fromPoints(_start, _current);
    final selectedNodeIds = context.document.nodes
        .where((node) => node.intersectsRect(selectionBounds))
        .map((node) => node.id)
        .toList();

    if (isShiftPressed) {
      for (final id in selectedNodeIds) {
        context.selection.selectFeature(id);
      }
    } else {
      context.selection.setSelection(selectedNodeIds);
    }
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: box state up");
    parent.transition(IdleInteractionState(parent: parent), context);
  }

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    print("Box selection paint");
    final screenBounds = Rect.fromPoints(
      camera.worldToScreen(_start),
      camera.worldToScreen(_current),
    );
    final worldBounds = camera.screenToWorldBounds(screenBounds);
    SelectionPainter.paintMarquee(canvas, worldBounds);
  }
}

class ClickCanvasState extends InteractionState {
  ClickCanvasState({required super.parent, required this._start});

  final Offset _start;

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final state = BoxSelectionState(
      parent: parent,
      start: _start,
      isShift: isShiftPressed,
    );
    parent.transition(state, context);
    state.onPointerMove(
      context,
      cursorWorldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: click canvas state up");
    if (!isShiftPressed) {
      context.selection.setSelection([]);
    }
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}

class ClickNodeState extends InteractionState {
  ClickNodeState({
    required super.parent,
    required this._start,
    required this._chase,
    required this.selectedNodes,
    required this.isShiftPressed,
  });

  final Offset _start;
  final Node _chase;
  final List<Node> selectedNodes;
  final bool isShiftPressed;
  late final bool _wasSelected = selectedNodes.any(
    (node) => node.id == _chase.id,
  );

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return EditorCursor.grabbing;
  }

  @override
  void onEnter(EditorContext context) {
    if (_wasSelected) {
      return;
    }

    if (isShiftPressed) {
      context.selection.selectFeature(_chase.id);
      selectedNodes.add(_chase);
    } else {
      context.selection.setSelection([_chase.id]);
      selectedNodes
        ..clear()
        ..add(_chase);
    }
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: click state move");
    if (selectedNodes.isNotEmpty) {
      final state = isAltPressed
          ? DuplicateState(
              parent: parent,
              start: _start,
              selectedNodes: selectedNodes,
              originsAtDragStart: {
                for (final node in selectedNodes) node.id: node.origin,
              },
              selectionAlreadyMoved: false,
            )
          : TranslateState(
              parent: parent,
              selectedNodes: selectedNodes,
              start: _start,
            );
      parent.transition(state, context);
      state.onPointerMove(
        context,
        cursorWorldPosition,
        camera,
        isShiftPressed: isShiftPressed,
        isAltPressed: isAltPressed,
      );
    }
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: click state up");
    if (isShiftPressed) {
      if (_wasSelected) {
        context.selection.deselectFeature(_chase.id);
      }
    } else {
      context.selection.setSelection([_chase.id]);
    }
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}

class DuplicateState extends InteractionState {
  DuplicateState({
    required super.parent,
    required this._start,
    required this._selectedNodes,
    required this._originsAtDragStart,
    required this._selectionAlreadyMoved,
  });

  final Offset _start;
  final List<Node> _selectedNodes;
  final Map<NodeId, Offset> _originsAtDragStart;
  final bool _selectionAlreadyMoved;

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final totalMotion = constrainedMoveDelta(
      _start,
      cursorWorldPosition,
      constrainToAxis: isShiftPressed,
    );
    final clones = _selectedNodes
        .map((node) => node.copyWith(id: noId))
        .toList();

    for (final node in _selectedNodes) {
      node.origin = _originsAtDragStart[node.id]!;
    }
    context.document.addNodes(clones);
    context.selection.setSelection(clones.map((node) => node.id).toList());

    final state = TranslateState(
      parent: parent,
      start: _start,
      selectedNodes: clones,
      initialOrigins: {
        for (final node in clones)
          node.id: _selectionAlreadyMoved
              ? node.origin - totalMotion
              : node.origin,
      },
      hasDuplicated: true,
    );
    parent.transition(state, context);
    state.onPointerMove(
      context,
      cursorWorldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }
}

class TranslateState extends InteractionState {
  TranslateState({
    required super.parent,
    required this._start,
    required this.selectedNodes,
    Map<NodeId, Offset>? initialOrigins,
    this._hasDuplicated = false,
  }) : _initialOrigins =
           initialOrigins ??
           {for (final node in selectedNodes) node.id: node.origin};

  final Offset _start;
  final List<Node> selectedNodes;
  final Map<NodeId, Offset> _initialOrigins;
  final bool _hasDuplicated;

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
    final totalMotion = constrainedMoveDelta(
      _start,
      cursorWorldPosition,
      constrainToAxis: isShiftPressed,
    );

    if (isAltPressed && !_hasDuplicated) {
      final state = DuplicateState(
        parent: parent,
        start: _start,
        selectedNodes: selectedNodes,
        originsAtDragStart: _initialOrigins,
        selectionAlreadyMoved: true,
      );
      parent.transition(state, context);
      state.onPointerMove(
        context,
        cursorWorldPosition,
        camera,
        isShiftPressed: isShiftPressed,
        isAltPressed: isAltPressed,
      );
      return;
    }

    for (var node in selectedNodes) {
      node.origin = _initialOrigins[node.id]! + totalMotion;
    }
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

class ResizeHandle {
  final Node node;
  final SelectionResizeHandle handle;
  final Rect geometry;

  ResizeHandle({
    required this.node,
    required this.handle,
    required this.geometry,
  });
}

class PolylineHandle {
  final Feature feature;
  final int pointIndex;
  final Rect geometry;

  PolylineHandle({
    required this.feature,
    required this.pointIndex,
    required this.geometry,
  });
}

class PolylineHandleUtil {
  static PolylineHandle? hitTest(Node node, Offset worldPoint, Camera camera) {
    if (node is! Feature) {
      return null;
    }

    final feature = node;
    if (feature.kind is! FeatureKindPolyline) {
      return null;
    }

    final polyline = feature.kind as FeatureKindPolyline;

    final screenPoint = camera.worldToScreen(worldPoint);
    for (final (pointIndex, localPoint) in polyline.localPoints.indexed) {
      final hitRect = Rect.fromCenter(
        center: camera.worldToScreen(feature.origin + localPoint),
        width: kSelectionHandleHitSize,
        height: kSelectionHandleHitSize,
      );
      if (hitRect.contains(screenPoint)) {
        return PolylineHandle(
          feature: feature,
          pointIndex: pointIndex,
          geometry: hitRect,
        );
      }
    }

    return null;
  }
}

class ResizeHandleUtil {
  static ResizeHandle? hitTest(Node node, Offset worldPoint, Camera camera) {
    final resizeHandles = getResizeHandles(node, camera);
    final screenPoint = camera.worldToScreen(worldPoint);
    for (final handle in resizeHandles) {
      if (handle.geometry.contains(screenPoint)) {
        return handle;
      }
    }
    return null;
  }

  static List<ResizeHandle> getResizeHandles(Node node, Camera camera) {
    const kSelectionBoxPadding = 8.0;
    const kSelectionHandleHitSize = 20.0;

    final screenBounds = camera.worldToScreenBounds(node.bounds());
    final inflated = screenBounds.inflate(kSelectionBoxPadding / camera.zoom);
    final half = kSelectionHandleHitSize / 2;
    const cornerSize = Size.square(kSelectionHandleHitSize);
    final horizontalSize = Size(inflated.width, kSelectionHandleHitSize);
    final verticalSize = Size(kSelectionHandleHitSize, inflated.height);

    final handles = <(SelectionResizeHandle, Offset, Size)>[
      (
        SelectionResizeHandle.topLeft,
        inflated.topLeft - Offset(half, half),
        cornerSize,
      ),
      (SelectionResizeHandle.top, inflated.topCenter, horizontalSize),
      (
        SelectionResizeHandle.topRight,
        inflated.topRight + Offset(half, -half),
        cornerSize,
      ),
      (SelectionResizeHandle.right, inflated.centerRight, verticalSize),
      (
        SelectionResizeHandle.bottomRight,
        inflated.bottomRight + Offset(half, half),
        cornerSize,
      ),
      (SelectionResizeHandle.bottom, inflated.bottomCenter, horizontalSize),
      (
        SelectionResizeHandle.bottomLeft,
        inflated.bottomLeft + Offset(-half, half),
        cornerSize,
      ),
      (SelectionResizeHandle.left, inflated.centerLeft, verticalSize),
    ];

    return handles.map((entry) {
      final (handle, center, size) = entry;
      return ResizeHandle(
        node: node,
        handle: handle,
        geometry: Rect.fromCenter(
          center: center,
          width: size.width,
          height: size.height,
        ),
      );
    }).toList();
  }
}
