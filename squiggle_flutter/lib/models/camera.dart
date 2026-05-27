import 'dart:ui';

/// 2D camera mapping world coordinates to canvas-local screen space.
///
/// All [screen] arguments are pixels relative to the [DocumentCanvas] render
/// box (top-left is `(0, 0)`). Flutter layout offset is applied in paint, not
/// here.
class Camera {
  Camera({this.location = Offset.zero, this.zoom = 1.0});

  Offset location;
  double zoom;

  Offset worldToScreen(Offset world) {
    return (world - location) / zoom;
  }

  Size worldSizeToScreenSize(Size size) {
    return size / zoom;
  }

  double worldLengthToScreenLength(double length) {
    return length / zoom;
  }

  double screenLengthToWorldLength(double length) {
    return length * zoom;
  }

  Offset screenToWorld(Offset screen) {
    return screen * zoom + location;
  }

  void panByScreenDelta(Offset delta) {
    location -= delta * zoom;
  }

  void zoomToward(Offset anchor, double factor) {
    final prevZoom = zoom;
    zoom = (zoom * factor).clamp(0.05, 10.0);
    location += anchor * (prevZoom - zoom);
  }

  Rect worldToScreenBounds(Rect worldBounds) {
    final screenOrigin = worldToScreen(worldBounds.topLeft);
    final screenSize = worldSizeToScreenSize(worldBounds.size);
    return Rect.fromLTWH(
      screenOrigin.dx,
      screenOrigin.dy,
      screenSize.width,
      screenSize.height,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    return other is Camera && other.location == location && other.zoom == zoom;
  }

  @override
  int get hashCode => Object.hash(location, zoom);
}
