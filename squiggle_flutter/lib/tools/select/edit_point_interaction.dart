import 'dart:ui';

import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import 'select_interaction.dart';

/// Drags one vertex of the polyline feature currently being edited.
class EditPointInteraction extends SelectInteraction {
  EditPointInteraction({
    required this.featureId,
    required this.pointIndex,
    required this.dragOffset,
    required this.initialOrigin,
    required this.initialLocalPoints,
  });

  final FeatureId featureId;
  final int pointIndex;
  final Offset dragOffset;
  final Offset initialOrigin;
  final List<Offset> initialLocalPoints;

  bool _didMove = false;

  bool get didMove => _didMove;

  @override
  void update(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final document = context.document;
    final feature = document.featureById(featureId)!;
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
    _didMove = true;
    document.setPolylinePoint(featureId, pointIndex, target);
  }

  @override
  void commit(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (!_didMove) return;

    final document = context.document;
    final feature = document.featureById(featureId);
    if (feature == null) return;

    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) return;

    final finalPoints = worldPoints(feature.origin, kind.localPoints);
    if (pointIndex < 0 || pointIndex >= finalPoints.length) return;

    final initialWorldPoints = worldPoints(initialOrigin, initialLocalPoints);
    if (pointIndex >= initialWorldPoints.length ||
        finalPoints[pointIndex] == initialWorldPoints[pointIndex]) {
      return;
    }

    context.record(
      MovePolylinePointCommand(
        id: featureId,
        pointIndex: pointIndex,
        initialOrigin: initialOrigin,
        initialLocalPoints: initialLocalPoints,
        finalWorldPosition: finalPoints[pointIndex],
      ),
    );
  }
}