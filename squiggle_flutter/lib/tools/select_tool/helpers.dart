import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/select_tool/hit_target.dart';
import 'package:squiggle_flutter/tools/select_tool/polyline_handle_util.dart';
import 'package:squiggle_flutter/tools/select_tool/resize_handle_util.dart';

enum SelectionResizeHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

HitTarget getTargetUnderCursor(EditorContext context, Offset worldPosition) {
  if (context.selection.selectedNodeIds.length == 1) {
    final node = context.document.nodeById(
      context.selection.selectedNodeIds.first,
    );
    if (node != null) {
      final polyHandle = PolylineHandleUtil.hitTest(
        node,
        worldPosition,
        context.camera,
      );
      if (polyHandle != null) {
        return PolylineHandleTarget(handle: polyHandle);
      }
      final handle = ResizeHandleUtil.hitTest(
        node,
        worldPosition,
        context.camera,
      );
      if (handle != null) {
        return ResizeHandleTarget(handle: handle);
      }
    }
  }

  final nodeUnderCursor = context.document.nodeAtPoint(worldPosition);
  if (nodeUnderCursor != null) {
    return NodeTarget(node: nodeUnderCursor);
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
