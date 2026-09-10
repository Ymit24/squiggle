import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'hit_target.dart';
import 'polyline_handle_util.dart';
import 'resize_handle_util.dart';

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
  if (context.selection.selectedNodes.length == 1) {
    final feature = context.document.featureById(
      context.selection.selectedNodes.first,
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
