part of '../select_tool_3.dart';

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
