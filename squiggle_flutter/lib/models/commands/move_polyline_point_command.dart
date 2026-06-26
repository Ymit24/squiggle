part of 'command.dart';

/// Moves one vertex of a polyline feature, capturing previous geometry for undo.
final class MovePolylinePointCommand extends Command {
  MovePolylinePointCommand(
    this.id,
    this.pointIndex,
    this.worldPosition, {
    Offset? previousOrigin,
    List<Offset>? previousLocalPoints,
  }) : // Keep the public named argument readable while storing private state.
       // ignore: prefer_initializing_formals
       _previousOrigin = previousOrigin,
       _previousLocalPoints = previousLocalPoints == null
           ? null
           : List.of(previousLocalPoints);

  final FeatureId id;
  final int pointIndex;
  final Offset worldPosition;
  Offset? _previousOrigin;
  List<Offset>? _previousLocalPoints;

  @override
  void apply(Document document) {
    final feature = document.featureById(id);
    if (feature == null) return;

    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) return;

    _previousOrigin ??= feature.origin;
    _previousLocalPoints ??= List.of(kind.localPoints);

    final points = worldPoints(feature.origin, kind.localPoints);
    if (pointIndex < 0 || pointIndex >= points.length) return;

    points[pointIndex] = worldPosition;
    final newOrigin = points.first;
    final newLocal = localPointsFromWorld(points, newOrigin);
    feature.moveTo(newOrigin);
    feature.kind = kind.copyWith(localPoints: newLocal);
    feature.size = feature.bounds().size;
  }

  @override
  void undo(Document document) {
    final previousOrigin = _previousOrigin;
    final previousLocalPoints = _previousLocalPoints;
    if (previousOrigin == null || previousLocalPoints == null) return;

    final feature = document.featureById(id);
    if (feature == null) return;

    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) return;

    feature.moveTo(previousOrigin);
    feature.kind = kind.copyWith(localPoints: previousLocalPoints);
    feature.size = feature.bounds().size;
  }

  @override
  Command clone() => MovePolylinePointCommand(id, pointIndex, worldPosition)
    .._previousOrigin = _previousOrigin
    .._previousLocalPoints = _previousLocalPoints;
}
