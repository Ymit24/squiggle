import 'dart:ui';

import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

import 'package:squiggle_flutter/tools/select_tool/polyline_handle.dart';

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
