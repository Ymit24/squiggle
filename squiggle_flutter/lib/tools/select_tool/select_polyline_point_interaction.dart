import 'dart:ui';

import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/tools/editor_interaction.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

/// Select-tool interaction for dragging a selected polyline vertex.
class SelectPolylinePointInteraction extends EditorInteraction {
  FeatureId? _featureId;
  int? _pointIndex;
  Offset? _dragOffset;
  Offset? _initialOrigin;
  List<Offset>? _initialLocalPoints;
  bool _didMove = false;

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final selection = context.selection;
    if (selection.selectedFeatures.length != 1) return false;

    final feature = context.document.featureById(
      selection.selectedFeatures.single,
    );
    if (feature == null || feature.kind is! FeatureKindPolyline) return false;

    final kind = feature.kind as FeatureKindPolyline;
    final points = worldPoints(feature.origin, kind.localPoints);
    final screenPoint = camera.worldToScreen(worldPosition);
    final pointIndex = points.indexWhere((point) {
      final center = camera.worldToScreen(point);
      return Rect.fromCenter(
        center: center,
        width: kSelectionHandleHitSize,
        height: kSelectionHandleHitSize,
      ).contains(screenPoint);
    });
    if (pointIndex < 0) return false;

    _featureId = feature.id;
    _pointIndex = pointIndex;
    _dragOffset = worldPosition - points[pointIndex];
    _initialOrigin = feature.origin;
    _initialLocalPoints = List.of(kind.localPoints);
    _didMove = false;
    return true;
  }

  @override
  bool onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final featureId = _featureId;
    final pointIndex = _pointIndex;
    final dragOffset = _dragOffset;
    if (featureId == null || pointIndex == null || dragOffset == null) {
      return false;
    }

    final feature = context.document.featureById(featureId);
    if (feature == null || feature.kind is! FeatureKindPolyline) return false;

    final kind = feature.kind as FeatureKindPolyline;
    final points = worldPoints(feature.origin, kind.localPoints);
    var target = worldPosition - dragOffset;
    if (isShiftPressed) {
      final origin = pointIndex > 0
          ? points[pointIndex - 1]
          : points.length > 1
          ? points[1]
          : target;
      target = snapPointTo45DegreeAngle(origin, target);
    }

    kind.setPoint(feature, pointIndex, target);
    context.notifyViewportChanged();
    _didMove = true;
    return true;
  }

  @override
  bool onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final featureId = _featureId;
    final pointIndex = _pointIndex;
    final initialOrigin = _initialOrigin;
    final initialLocalPoints = _initialLocalPoints;
    final feature = featureId == null
        ? null
        : context.document.featureById(featureId);

    if (_didMove &&
        feature != null &&
        feature.kind is FeatureKindPolyline &&
        pointIndex != null &&
        initialOrigin != null &&
        initialLocalPoints != null) {
      final kind = feature.kind as FeatureKindPolyline;
      final finalPoints = worldPoints(feature.origin, kind.localPoints);
      final initialPoints = worldPoints(initialOrigin, initialLocalPoints);
      if (pointIndex < finalPoints.length &&
          pointIndex < initialPoints.length &&
          finalPoints[pointIndex] != initialPoints[pointIndex]) {
        context.record(
          MovePolylinePointCommand(
            id: featureId!,
            pointIndex: pointIndex,
            initialOrigin: initialOrigin,
            initialLocalPoints: initialLocalPoints,
            finalWorldPosition: finalPoints[pointIndex],
          ),
        );
      }
    }

    _clear();
    return true;
  }

  @override
  void deactivate(EditorContext context) => _clear();

  void _clear() {
    _featureId = null;
    _pointIndex = null;
    _dragOffset = null;
    _initialOrigin = null;
    _initialLocalPoints = null;
    _didMove = false;
  }
}

/// Select-tool interaction for resizing one selected feature.
