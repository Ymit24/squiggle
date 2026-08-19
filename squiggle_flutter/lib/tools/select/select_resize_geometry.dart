import 'dart:ui';

import 'package:squiggle_flutter/models/feature_geometry.dart';

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

/// World-space anchor (the corner opposite the dragged handle) for asymmetric
/// resizing: the part of the feature that stays fixed while resizing.
Offset anchorForResizeHandle(SelectionResizeHandle handle, Rect bounds) {
  return switch (handle) {
    SelectionResizeHandle.topLeft => bounds.bottomRight,
    SelectionResizeHandle.top => bounds.bottomLeft,
    SelectionResizeHandle.topRight => bounds.bottomLeft,
    SelectionResizeHandle.right => bounds.topLeft,
    SelectionResizeHandle.bottomRight => bounds.topLeft,
    SelectionResizeHandle.bottom => bounds.topLeft,
    SelectionResizeHandle.bottomLeft => bounds.topRight,
    SelectionResizeHandle.left => bounds.topRight,
  };
}

/// World-space point the pointer grab offset is measured against for a handle.
Offset referencePointForResizeHandle(
  SelectionResizeHandle handle,
  Rect bounds,
) {
  return switch (handle) {
    SelectionResizeHandle.topLeft => bounds.topLeft,
    SelectionResizeHandle.top => bounds.topLeft,
    SelectionResizeHandle.topRight => bounds.topRight,
    SelectionResizeHandle.right => bounds.bottomRight,
    SelectionResizeHandle.bottomRight => bounds.bottomRight,
    SelectionResizeHandle.bottom => bounds.bottomRight,
    SelectionResizeHandle.bottomLeft => bounds.bottomLeft,
    SelectionResizeHandle.left => bounds.topLeft,
  };
}

/// New bounds for a resize where [anchor] stays fixed and [dragged] is the
/// pointer position relative to the grab offset.
Rect asymmetricBoundsForResize(
  SelectionResizeHandle handle,
  Offset anchor,
  Rect bounds,
  Offset dragged, {
  required bool lockAspectRatio,
  required double aspectRatio,
}) {
  if (lockAspectRatio) {
    return switch (handle) {
      SelectionResizeHandle.topLeft ||
      SelectionResizeHandle.topRight ||
      SelectionResizeHandle.bottomLeft ||
      SelectionResizeHandle.bottomRight => rectFromAnchorWithAspectRatio(
        anchor,
        dragged,
        aspectRatio,
      ),
      SelectionResizeHandle.top => edgeResizeWithAspectRatio(
        bounds,
        dragged,
        resizeTop: true,
        resizeBottom: false,
        resizeLeft: false,
        resizeRight: false,
        aspectRatio: aspectRatio,
      ),
      SelectionResizeHandle.bottom => edgeResizeWithAspectRatio(
        bounds,
        dragged,
        resizeTop: false,
        resizeBottom: true,
        resizeLeft: false,
        resizeRight: false,
        aspectRatio: aspectRatio,
      ),
      SelectionResizeHandle.left => edgeResizeWithAspectRatio(
        bounds,
        dragged,
        resizeTop: false,
        resizeBottom: false,
        resizeLeft: true,
        resizeRight: false,
        aspectRatio: aspectRatio,
      ),
      SelectionResizeHandle.right => edgeResizeWithAspectRatio(
        bounds,
        dragged,
        resizeTop: false,
        resizeBottom: false,
        resizeLeft: false,
        resizeRight: true,
        aspectRatio: aspectRatio,
      ),
    };
  }

  return switch (handle) {
    SelectionResizeHandle.topLeft ||
    SelectionResizeHandle.topRight ||
    SelectionResizeHandle.bottomLeft ||
    SelectionResizeHandle.bottomRight => Rect.fromPoints(anchor, dragged),
    SelectionResizeHandle.top => Rect.fromLTRB(
      bounds.left,
      dragged.dy,
      bounds.right,
      bounds.bottom,
    ),
    SelectionResizeHandle.bottom => Rect.fromLTRB(
      bounds.left,
      bounds.top,
      bounds.right,
      dragged.dy,
    ),
    SelectionResizeHandle.left => Rect.fromLTRB(
      dragged.dx,
      bounds.top,
      bounds.right,
      bounds.bottom,
    ),
    SelectionResizeHandle.right => Rect.fromLTRB(
      bounds.left,
      bounds.top,
      dragged.dx,
      bounds.bottom,
    ),
  };
}

/// New bounds for a resize that stays symmetric around the feature center.
Rect symmetricBoundsForResize(
  SelectionResizeHandle handle,
  Rect initialBounds,
  Offset dragged, {
  required bool lockAspectRatio,
  required double aspectRatio,
}) {
  final center = initialBounds.center;
  if (lockAspectRatio) {
    return switch (handle) {
      SelectionResizeHandle.topLeft ||
      SelectionResizeHandle.topRight ||
      SelectionResizeHandle.bottomLeft ||
      SelectionResizeHandle.bottomRight => symmetricRectWithAspectRatio(
        center,
        dragged,
        aspectRatio,
        resizeHorizontal: true,
        resizeVertical: true,
      ),
      SelectionResizeHandle.top ||
      SelectionResizeHandle.bottom => symmetricRectWithAspectRatio(
        center,
        dragged,
        aspectRatio,
        resizeHorizontal: false,
        resizeVertical: true,
      ),
      SelectionResizeHandle.left ||
      SelectionResizeHandle.right => symmetricRectWithAspectRatio(
        center,
        dragged,
        aspectRatio,
        resizeHorizontal: true,
        resizeVertical: false,
      ),
    };
  }

  return switch (handle) {
    SelectionResizeHandle.topLeft ||
    SelectionResizeHandle.topRight ||
    SelectionResizeHandle.bottomLeft ||
    SelectionResizeHandle.bottomRight => Rect.fromCenter(
      center: center,
      width: (dragged.dx - center.dx).abs() * 2,
      height: (dragged.dy - center.dy).abs() * 2,
    ),
    SelectionResizeHandle.top ||
    SelectionResizeHandle.bottom => Rect.fromCenter(
      center: center,
      width: initialBounds.width,
      height: (dragged.dy - center.dy).abs() * 2,
    ),
    SelectionResizeHandle.left ||
    SelectionResizeHandle.right => Rect.fromCenter(
      center: center,
      width: (dragged.dx - center.dx).abs() * 2,
      height: initialBounds.height,
    ),
  };
}
