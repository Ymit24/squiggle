import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/grouping_commands.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/select_tool/click_canvas_state.dart';
import 'package:squiggle_flutter/tools/select_tool/click_node_state.dart';
import 'package:squiggle_flutter/tools/select_tool/drag_polyline_handle_state.dart';
import 'package:squiggle_flutter/tools/select_tool/helpers.dart';
import 'package:squiggle_flutter/tools/select_tool/hit_target.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/resize_state.dart';

class IdleInteractionState extends SelectInteractionState {
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
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final target = getTargetUnderCursor(context, worldPosition);
    switch (target) {
      case ResizeHandleTarget(handle: var handle):
        parent.transition(
          ResizeState(
            parent: parent,
            handle: handle,
            pointerDownWorld: worldPosition,
          ),
          context,
        );
        break;
      case PolylineHandleTarget(handle: var handle):
        parent.transition(
          DragPolylineHandleState(
            parent: parent,
            handle: handle,
            pointerDownWorld: worldPosition,
          ),
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
            start: worldPosition,
            chase: chaseNode,
            selectedNodes: selectedNodes.toList(),
            isShiftPressed: isShiftPressed,
          ),
          context,
        );
        break;
      case CanvasTarget():
        parent.transition(
          ClickCanvasState(parent: parent, start: worldPosition),
          context,
        );
        break;
    }
  }

  @override
  void onDoubleClick(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    final target = getTargetUnderCursor(context, worldPosition);
    if (target case NodeTarget(
      node: final Feature feature,
    ) when feature.kind is LabelCapable) {
      final text = feature.kind as LabelCapable;
      context.selection.setSelection([feature.id]);
      context.startTextEdit(
        EditTextEditSession(
          featureId: feature.id,
          initialContents: text.label,
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
          ungroupSelectedNodes(context);
        } else {
          groupSelectedNodes(context);
        }
        return true;
      default:
        return false;
    }
  }

  void _onDeletePress(EditorContext context) {
    final selectedIds = context.selection.selectedNodeIds.toList();
    final container = context.document
        .requireNodeById(selectedIds.first)
        .parent;

    context.selection.clearSelection();
    try {
      context.history.run('Delete Selected Nodes', (transaction) {
        transaction.removeAll(selectedIds);
      }, container: container);
    } catch (_) {
      context.selection.setSelection(
        selectedIds.where((id) => context.document.nodeById(id) != null),
      );
      rethrow;
    }
  }
}
