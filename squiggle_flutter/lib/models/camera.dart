import 'dart:ui';

/// 2D camera mapping world coordinates to screen space.
class Camera {
  Camera({
    this.location = Offset.zero,
    this.zoom = 1.0,
    this.viewportOrigin = Offset.zero,
  });

  Offset location;
  double zoom;
  Offset viewportOrigin;

  void setViewportOrigin(Offset origin) {
    viewportOrigin = origin;
  }

  Offset worldToScreen(Offset world) {
    return viewportOrigin + (world - location) / zoom;
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
    return (screen - viewportOrigin) * zoom + location;
  }

  void panByScreenDelta(Offset delta) {
    location -= delta * zoom;
  }

  void zoomToward(Offset anchor, double factor) {
    final adjustedAnchor = anchor - viewportOrigin;
    final prevZoom = zoom;
    zoom = (zoom * factor).clamp(0.05, 10.0);
    location += adjustedAnchor * (prevZoom - zoom);
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
    return other is Camera &&
        other.location == location &&
        other.zoom == zoom &&
        other.viewportOrigin == viewportOrigin;
  }

  @override
  int get hashCode => Object.hash(location, zoom, viewportOrigin);
}
