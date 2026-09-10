import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'click_canvas_state.dart';
import 'click_node_state.dart';
import 'drag_polyline_handle_state.dart';
import 'helpers.dart';
import 'hit_target.dart';
import 'interaction_state.dart';
import 'resize_state.dart';

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
    switch (target) {
      case ResizeHandleTarget(handle: var handle):
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
        parent.transition(
          DragPolylineHandleState(parent: parent, handle: handle),
          context,
        );
        break;
      case NodeTarget(node: var chaseNode):
        final selectedNodes = context.selection.selectedNodes.map(
          (id) => context.document.nodeById(id),
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
    if (target case NodeTarget(
      node: final Feature feature,
    ) when feature.kind is FeatureKindText) {
      final text = feature.kind as FeatureKindText;
      context.selection.setSelection([feature.id]);
      context.startTextEdit(
        EditTextEditSession(
          featureId: feature.id,
          initialContents: text.contents,
          canvasLocalBounds: camera.worldToScreenBounds(feature.localBounds()),
        ),
      );
      return;
    }
  }

  @override
  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    if (context.selection.isEmpty) {
      return false;
    }

    switch (event.logicalKey) {
      case LogicalKeyboardKey.delete:
      case LogicalKeyboardKey.backspace:
        _onDeletePress(context);
        return true;
      case LogicalKeyboardKey.keyG:
        final keyboard = HardwareKeyboard.instance;
        if (!(keyboard.isControlPressed || keyboard.isMetaPressed)) {
          return false;
        }
        if (keyboard.isShiftPressed) {
          _onShiftCtrlCmdGPress(context);
        } else {
          _onCtrlCmdGPress(context);
        }
        return true;
      default:
        return false;
    }
  }

  void _onDeletePress(EditorContext context) {
    final container = context.document
        .nodeById(context.selection.selectedNodes.first)
        ?.parent;

    context.history.run('Delete Selected Nodes', (transaction) {
      transaction.removeAll(context.selection.selectedNodes);
    }, container: container);

    context.selection.clearSelection();
  }

  void _onCtrlCmdGPress(EditorContext context) {
    if (context.selection.selectedNodes.length < 2) {
      return;
    }

    final selectedNodes = context.selection.selectedNodes
        .map((id) => context.document.nodeById(id))
        .where((node) => node != null)
        .map((node) => node!)
        .toList();

    context.history.run('Group Selected Nodes', (transaction) {
      transaction.removeAll(context.selection.selectedNodes);
      final bounds = Node.localBoundsOfNodes(selectedNodes);

      for (final node in selectedNodes) {
        node.origin -= bounds.center;
      }
      Group group = Group(
        children: selectedNodes.toList(),
        origin: bounds.center,
      );
      transaction.add(group);
      context.selection.setSelection([group.id]);
    });
  }

  void _onShiftCtrlCmdGPress(EditorContext context) {
    if (context.selection.selectedNodes.isEmpty) {
      return;
    }

    final selectedNodes = context.selection.selectedNodes
        .map((id) => context.document.nodeById(id))
        .where((node) => node != null)
        .whereType<Group>()
        .toList();

    if (selectedNodes.isEmpty) {
      return;
    }

    final newSelection = <NodeId>[];
    for (final node in selectedNodes) {
      final group = node;

      final container = group.parent!;
      final index = container.children.indexOf(group);
      final children = group.children.toList();
      final groupOrigin = group.origin;

      context.history.run('Ungroup Selected Nodes', (transaction) {
        transaction.removeAll([node.id]);
        node.removeAll(node.children.map((child) => child.id));
        for (var i = 0; i < children.length; i++) {
          final child = children[i];

          // Convert from group space to the group's parent space.
          child.origin += groupOrigin;

          transaction.add(child, index: index + i);
        }
      }, container: container);

      newSelection.addAll(children.map((child) => child.id));
    }
    context.selection.setSelection(newSelection);
  }
}
