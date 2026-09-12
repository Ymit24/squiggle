import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/select_tool/click_canvas_state.dart';
import 'package:squiggle_flutter/tools/select_tool/click_node_state.dart';
import 'package:squiggle_flutter/tools/select_tool/drag_polyline_handle_state.dart';
import 'package:squiggle_flutter/tools/select_tool/helpers.dart';
import 'package:squiggle_flutter/tools/select_tool/hit_target.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/resize_state.dart';

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
        final selectedNodes = context.selection.selectedNodeIds.map(
          context.document.requireNodeById,
        );
        parent.transition(
          ClickNodeState(
            parent: parent,
            start: cursorWorldPosition,
            chase: chaseNode,
            selectedNodes: selectedNodes.toList(),
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
    } else if (target is CanvasTarget) {
      context.startTextEdit(
        CreateTextEditSession(
          worldOrigin: worldPosition,
          initialContents: '',
          canvasLocalBounds: camera.worldToScreenBounds(
            newTextBoundsAt(worldPosition),
          ),
        ),
      );
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
        .requireNodeById(context.selection.selectedNodeIds.first)
        .parent;

    context.history.run('Delete Selected Nodes', (transaction) {
      transaction.removeAll(context.selection.selectedNodeIds);
    }, container: container);

    context.selection.clearSelection();
  }

  void _onCtrlCmdGPress(EditorContext context) {
    if (context.selection.selectedNodeIds.length < 2) {
      return;
    }

    final selectedIds = context.selection.selectedNodeIds.toSet();
    final container = context.document
        .requireNodeById(selectedIds.first)
        .parent;
    if (container == null) return;
    final siblings = container.children.toList();
    final selectedNodes = siblings
        .where((node) => selectedIds.contains(node.id))
        .toList();
    if (selectedNodes.length != selectedIds.length) return;
    final topmostSelectedIndex = siblings.lastIndexWhere(
      (node) => selectedIds.contains(node.id),
    );
    final insertionIndex = siblings
        .take(topmostSelectedIndex)
        .where((node) => !selectedIds.contains(node.id))
        .length;

    context.history.run('Group Selected Nodes', (transaction) {
      transaction.removeAll(selectedIds);
      final bounds = Node.localBoundsOfNodes(selectedNodes);

      for (final node in selectedNodes) {
        node.origin -= bounds.center;
      }
      final group = Group(
        children: selectedNodes.toList(),
        origin: bounds.center,
      );
      transaction.add(group, index: insertionIndex);
      context.selection.setSelection([group.id]);
    }, container: container);
  }

  void _onShiftCtrlCmdGPress(EditorContext context) {
    if (context.selection.selectedNodeIds.isEmpty) {
      return;
    }

    final selectedNodes = context.selection.selectedNodeIds
        .map(context.document.requireNodeById)
        .whereType<Group>()
        .toList();

    if (selectedNodes.isEmpty) {
      return;
    }

    final container = selectedNodes.first.parent;
    if (container == null ||
        selectedNodes.any((group) => !identical(group.parent, container))) {
      return;
    }
    final selectedIds = selectedNodes.map((group) => group.id).toSet();
    final originalOrder = container.children.toList();
    final newSelection = <NodeId>[];
    context.history.run('Ungroup Selected Nodes', (transaction) {
      transaction.removeAll(selectedIds);
      final replacementIds = <NodeId, List<NodeId>>{};
      for (final group in selectedNodes) {
        final children = group.children.toList();
        group.removeAll(children.map((child) => child.id));
        for (final child in children) {
          child.origin += group.origin;
          transaction.add(child);
        }
        replacementIds[group.id] = children.map((child) => child.id).toList();
        newSelection.addAll(children.map((child) => child.id));
      }
      transaction.reorder([
        for (final node in originalOrder)
          if (replacementIds[node.id] case final children?)
            ...children
          else
            node.id,
      ]);
    }, container: container);
    context.selection.setSelection(newSelection);
  }
}
