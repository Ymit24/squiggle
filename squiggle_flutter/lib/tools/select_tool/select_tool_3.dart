import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';
import 'package:squiggle_flutter/tools/tool.dart';

class SelectTool extends Tool {
  late InteractionState _activeInteractionState = IdleInteractionState(
    parent: this,
  );

  void transition(InteractionState state) {
    _activeInteractionState = state;
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
      CanvasTarget(),
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
  ) {}
}

abstract class InteractionState {
  final SelectTool parent;

  InteractionState({required this.parent});

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
}

class HitTarget {}

class CanvasTarget extends HitTarget {}

class NodeTarget extends HitTarget {
  final Node node;

  NodeTarget({required this.node});
}

class HandleTarget extends HitTarget {
  final SelectionResizeHandle handle;

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
    switch (target) {
      case HandleTarget():
        // parent.transition("resize");
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
        );
        break;
      case CanvasTarget():
        // parent.transition();
        break;
    }
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
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (isAltPressed) {
      parent.transition(
        DuplicateState(
          parent: parent,
          chase: _chase,
          selectedNodes: selectedNodes,
          start: _start,
        ),
      );
    } else {
      parent.transition(
        TranslateState(
          parent: parent,
          chase: _chase,
          selectedNodes: selectedNodes,
          start: _start,
        ),
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
    parent.transition(IdleInteractionState(parent: parent));
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

  void onEnter(EditorContext context) {
    final cloneNodes = selectedNodes.map((f) => f.copyWith(id: noId)).toList();
    context.document.addNodes(cloneNodes);

    parent.transition(
      TranslateState(
        parent: parent,
        start: _start,
        chase: _chase,
        selectedNodes: cloneNodes,
      ),
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
    parent.transition(IdleInteractionState(parent: parent));
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
    parent.transition(IdleInteractionState(parent: parent));
  }
}
