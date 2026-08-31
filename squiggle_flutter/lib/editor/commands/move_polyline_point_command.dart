import 'dart:ui';

import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import 'command.dart';

/// Moves one vertex of a polyline feature, restoring the previous geometry on
/// undo.
final class MovePolylinePointCommand extends Command {
  MovePolylinePointCommand({
    required this.id,
    required this.pointIndex,
    required this.initialOrigin,
    required this.initialLocalPoints,
    required this.finalWorldPosition,
  });

  final FeatureId id;
  final int pointIndex;
  final Offset initialOrigin;
  final List<Offset> initialLocalPoints;
  final Offset finalWorldPosition;

  @override
  void redo(Document document) {
    final feature = document.featureById(id);
    if (feature == null) return;
    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) return;
    kind.setPoint(feature, pointIndex, finalWorldPosition);
    document.notifyChanged();
  }

  @override
  void undo(Document document) {
    final feature = document.featureById(id);
    if (feature == null) return;
    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) return;
    kind.setGeometry(
      feature,
      origin: initialOrigin,
      localPoints: initialLocalPoints,
    );
    document.notifyChanged();
  }
}
