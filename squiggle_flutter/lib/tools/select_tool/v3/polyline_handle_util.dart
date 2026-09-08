part of '../select_tool_3.dart';

class PolylineHandleUtil {
  static PolylineHandle? hitTest(Node node, Offset worldPoint, Camera camera) {
    if (node is! Feature) {
      return null;
    }

    final feature = node;
    if (feature.kind is! FeatureKindPolyline) {
      return null;
    }

    final polyline = feature.kind as FeatureKindPolyline;

    final screenPoint = camera.worldToScreen(worldPoint);
    for (final (pointIndex, localPoint) in polyline.localPoints.indexed) {
      final hitRect = Rect.fromCenter(
        center: camera.worldToScreen(feature.origin + localPoint),
        width: kSelectionHandleHitSize,
        height: kSelectionHandleHitSize,
      );
      if (hitRect.contains(screenPoint)) {
        return PolylineHandle(
          feature: feature,
          pointIndex: pointIndex,
          geometry: hitRect,
        );
      }
    }

    return null;
  }
}
