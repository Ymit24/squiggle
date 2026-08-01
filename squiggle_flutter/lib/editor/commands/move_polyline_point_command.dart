import 'dart:ui';

import 'package:squiggle_flutter/models/document.dart';
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
    document.setPolylinePoint(id, pointIndex, finalWorldPosition);
  }

  @override
  void undo(Document document) {
    document.setPolylineGeometry(
      id,
      origin: initialOrigin,
      localPoints: initialLocalPoints,
    );
  }
}
