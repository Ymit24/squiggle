import 'dart:ui';

import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import 'select_resize_geometry.dart';

const kSelectionBoxPadding = 8.0;
const kSelectionHandleHitSize = 20.0;

Rect selectionBoxWorldBounds(Rect featureBounds) {
  return featureBounds.inflate(kSelectionBoxPadding);
}

/// Result of hit-testing a world point while SelectTool is active. Both cursor
/// resolution and interaction dispatch use this single result.
sealed class SelectHitTest {
  const SelectHitTest();
}

final class PolylineVertexHit extends SelectHitTest {
  const PolylineVertexHit(this.featureId, this.pointIndex);

  final FeatureId featureId;
  final int pointIndex;
}

final class ResizeHandleHit extends SelectHitTest {
  const ResizeHandleHit(this.handle);

  final SelectionResizeHandle handle;
}

final class FeatureHit extends SelectHitTest {
  const FeatureHit(this.featureId);

  final FeatureId featureId;
}

final class SelectionBoxHit extends SelectHitTest {
  const SelectionBoxHit();
}

final class EmptyHit extends SelectHitTest {
  const EmptyHit();
}

class SelectHitTester {
  const SelectHitTester();

  SelectHitTest hitTest({
    required Document document,
    required SelectionModel selection,
    required Offset worldPoint,
    required Camera camera,
    FeatureId? editingFeatureId,
  }) {
    if (editingFeatureId != null) {
      final feature = document.featureById(editingFeatureId);
      if (feature != null) {
        final pointIndex = _hitTestPolylineVertex(
          worldPoint: worldPoint,
          feature: feature,
          camera: camera,
        );
        if (pointIndex != null) {
          return PolylineVertexHit(editingFeatureId, pointIndex);
        }
      }
    }

    if (selection.selectedFeatures.length == 1) {
      final selected = document.featureById(selection.selectedFeatures.single);
      if (selected != null) {
        final bounds = selected.bounds();
        final handle = _hitTestResizeHandle(
          worldPoint: worldPoint,
          featureBounds: bounds,
          camera: camera,
        );
        if (handle != null) {
          return ResizeHandleHit(handle);
        }
      }
    }

    final feature = document.featureAtPoint(worldPoint);
    if (feature != null) {
      return FeatureHit(feature.id);
    }

    if (selection.selectedFeatures.length == 1) {
      final selected = document.featureById(selection.selectedFeatures.single);
      if (selected != null &&
          selectionBoxWorldBounds(selected.bounds()).contains(worldPoint)) {
        return const SelectionBoxHit();
      }
    }

    return const EmptyHit();
  }

  int? _hitTestPolylineVertex({
    required Offset worldPoint,
    required Feature feature,
    required Camera camera,
  }) {
    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) return null;

    final screenPoint = camera.worldToScreen(worldPoint);
    final points = worldPoints(feature.origin, kind.localPoints);
    for (var i = 0; i < points.length; i++) {
      final screenCenter = camera.worldToScreen(points[i]);
      final hitRect = Rect.fromCenter(
        center: screenCenter,
        width: kSelectionHandleHitSize,
        height: kSelectionHandleHitSize,
      );
      if (hitRect.contains(screenPoint)) {
        return i;
      }
    }
    return null;
  }

  SelectionResizeHandle? _hitTestResizeHandle({
    required Offset worldPoint,
    required Rect featureBounds,
    required Camera camera,
  }) {
    final screenPoint = camera.worldToScreen(worldPoint);
    final screenBounds = camera.worldToScreenBounds(featureBounds);
    final inflated = screenBounds.inflate(kSelectionBoxPadding / camera.zoom);
    final half = kSelectionHandleHitSize / 2;

    final handleCenters = <(SelectionResizeHandle, Offset)>[
      (SelectionResizeHandle.topLeft, inflated.topLeft - Offset(half, half)),
      (SelectionResizeHandle.topRight, inflated.topRight + Offset(half, -half)),
      (
        SelectionResizeHandle.bottomLeft,
        inflated.bottomLeft + Offset(-half, half),
      ),
      (
        SelectionResizeHandle.bottomRight,
        inflated.bottomRight + Offset(half, half),
      ),
    ];

    for (final (handle, center) in handleCenters) {
      final hitRect = Rect.fromCenter(
        center: center,
        width: kSelectionHandleHitSize,
        height: kSelectionHandleHitSize,
      );
      if (hitRect.contains(screenPoint)) {
        return handle;
      }
    }

    if (inflated.width <= kSelectionHandleHitSize ||
        inflated.height <= kSelectionHandleHitSize) {
      return null;
    }

    final edgeStrips = <(SelectionResizeHandle, Rect)>[
      (
        SelectionResizeHandle.top,
        Rect.fromLTWH(
          inflated.left + half,
          inflated.top - half,
          inflated.width - kSelectionHandleHitSize,
          kSelectionHandleHitSize,
        ),
      ),
      (
        SelectionResizeHandle.bottom,
        Rect.fromLTWH(
          inflated.left + half,
          inflated.bottom - half,
          inflated.width - kSelectionHandleHitSize,
          kSelectionHandleHitSize,
        ),
      ),
      (
        SelectionResizeHandle.left,
        Rect.fromLTWH(
          inflated.left - half,
          inflated.top + half,
          kSelectionHandleHitSize,
          inflated.height - kSelectionHandleHitSize,
        ),
      ),
      (
        SelectionResizeHandle.right,
        Rect.fromLTWH(
          inflated.right - half,
          inflated.top + half,
          kSelectionHandleHitSize,
          inflated.height - kSelectionHandleHitSize,
        ),
      ),
    ];

    for (final (handle, strip) in edgeStrips) {
      if (strip.contains(screenPoint)) {
        return handle;
      }
    }
    return null;
  }
}