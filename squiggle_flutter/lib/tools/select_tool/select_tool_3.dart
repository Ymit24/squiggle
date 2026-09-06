import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/selection_painter.dart';
import 'package:squiggle_flutter/tools/tool.dart';

HitTarget getTargetUnderCursor(EditorContext context, Offset worldPosition) {
  if (context.selection.selectedFeatures.length == 1) {
    print("D: single selection, checking resize handles");
    final feature = context.document.featureById(
      context.selection.selectedFeatures.first,
    );
    print("D: feature found: $feature");
    if (feature != null) {
      final handle = ResizeHandleUtil.hitTest(
        feature,
        worldPosition,
        context.camera,
      );
      print("D: resize handle found: $handle");
      if (handle != null) {
        return HandleTarget(handle: handle);
      }
    }
  }
  final feature = context.document.featureAtPoint(worldPosition);
  if (feature != null) {
    return NodeTarget(node: feature);
  }

  return CanvasTarget();
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
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    _activeInteractionState.paint(canvas, camera, context, imageRepository);

    SelectionPainter.paintSelectedFeatureBoxes(canvas, camera, context);
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

  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {}
}

class HitTarget {}

class CanvasTarget extends HitTarget {}

class NodeTarget extends HitTarget {
  final Node node;

  NodeTarget({required this.node});
}

class HandleTarget extends HitTarget {
  final ResizeHandle handle;

  HandleTarget({required this.handle});
}

class IdleInteractionState extends InteractionState {
  IdleInteractionState({required super.parent});

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
      case HandleTarget(handle: var handle):
        print("D: Clicked on handle: ${target.handle}");
        parent.transition(ResizeState(parent: parent, handle: handle), context);
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
}

class ResizeState extends InteractionState {
  ResizeState({required super.parent, required this._handle});

  final ResizeHandle _handle;
  late final Rect _initialBounds = _handle.node.bounds();

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: on pointer move");

    final newBounds = getNewBounds(cursorWorldPosition);
    _handle.node.resize(newBounds);
  }

  Rect getNewBounds(Offset cursorWorldPosition) {
    final left = switch (_handle.handle) {
      SelectionResizeHandle.topLeft ||
      SelectionResizeHandle.left ||
      SelectionResizeHandle.bottomLeft => cursorWorldPosition.dx,
      _ => _initialBounds.left,
    };

    final right = switch (_handle.handle) {
      SelectionResizeHandle.topRight ||
      SelectionResizeHandle.right ||
      SelectionResizeHandle.bottomRight => cursorWorldPosition.dx,
      _ => _initialBounds.right,
    };

    final top = switch (_handle.handle) {
      SelectionResizeHandle.topLeft ||
      SelectionResizeHandle.top ||
      SelectionResizeHandle.topRight => cursorWorldPosition.dy,
      _ => _initialBounds.top,
    };

    final bottom = switch (_handle.handle) {
      SelectionResizeHandle.bottomLeft ||
      SelectionResizeHandle.bottom ||
      SelectionResizeHandle.bottomRight => cursorWorldPosition.dy,
      _ => _initialBounds.bottom,
    };

    return Rect.fromPoints(Offset(left, top), Offset(right, bottom));
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
    parent.transition(
      BoxSelectionState(parent: parent, start: _start, isShift: isShiftPressed),
      context,
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
    context.selection.setSelection([]);
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}

class ClickNodeState extends InteractionState {
  ClickNodeState({
    required super.parent,
    required this._start,
    required this._chase,
    required this.selectedNodes,
  });

  final Offset _start;
  final Node _chase;
  final List<Node> selectedNodes;

  @override
  void onEnter(EditorContext context) {
    if (context.selection.isFeatureSelected(_chase.id)) {
      return;
    }

    context.selection.setSelection([_chase.id]);
    selectedNodes.clear();
    selectedNodes.add(_chase);
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
      if (isAltPressed) {
        parent.transition(
          DuplicateState(
            parent: parent,
            chase: _chase,
            selectedNodes: selectedNodes,
            start: _start,
          ),
          context,
        );
      } else {
        parent.transition(
          TranslateState(
            parent: parent,
            chase: _chase,
            selectedNodes: selectedNodes,
            start: _start,
          ),
          context,
        );
      }
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
    // if (context.selection.isFeatureSelected(_chase.id)) {
    //   context.selection.setSelection([]);
    // } else {
    //   context.selection.setSelection([_chase.id]);
    // }
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}

class DuplicateState extends InteractionState {
  DuplicateState({
    required super.parent,
    required this._start,
    required this._chase,
    required this.selectedNodes,
  });

  final Offset _start;
  final Node _chase;
  final List<Node> selectedNodes;

  @override
  void onEnter(EditorContext context) {
    print("D: duplicate state enter");
    final cloneNodes = selectedNodes.map((f) => f.copyWith(id: noId)).toList();
    context.document.addNodes(cloneNodes);

    parent.transition(
      TranslateState(
        parent: parent,
        start: _start,
        chase: _chase,
        selectedNodes: selectedNodes,
      ),
      context,
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
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}

class TranslateState extends InteractionState {
  TranslateState({
    required super.parent,
    required this._start,
    required Node chase,
    required this.selectedNodes,
  }) {
    _initialOrigins = {for (final node in selectedNodes) node.id: node.origin};
  }

  final Offset _start;
  final List<Node> selectedNodes;
  late final Map<NodeId, Offset> _initialOrigins;

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final totalMotion = cursorWorldPosition - _start;

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

class ResizeHandleUtil {
  static ResizeHandle? hitTest(Node node, Offset worldPoint, Camera camera) {
    final resizeHandles = getResizeHandles(node, camera);
    print(
      "D: location of resize handles: ${resizeHandles.map((h) => h.geometry).toList()}",
    );
    print("D: Location of worldPoint: $worldPoint");
    final screenPoint = camera.worldToScreen(worldPoint);
    print("D: Location of screenPoint: $screenPoint");
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

    final handleCenters = <(SelectionResizeHandle, Offset)>[
      (SelectionResizeHandle.topLeft, inflated.topLeft - Offset(half, half)),
      (SelectionResizeHandle.topRight, inflated.topRight + Offset(half, -half)),
      (
        SelectionResizeHandle.bottomLeft,
        inflated.bottomLeft + Offset(-half, half),
      ),
      (
        SelectionResizeHandle.bottomRight,
        inflated.bottomRight + Offset(half, half),
      ),
    ];

    return handleCenters.map((info) {
      final (handle, center) = info;
      return ResizeHandle(
        node: node,
        handle: handle,
        geometry: Rect.fromCenter(
          center: center,
          width: kSelectionHandleHitSize,
          height: kSelectionHandleHitSize,
        ),
      );
    }).toList();
  }
}
