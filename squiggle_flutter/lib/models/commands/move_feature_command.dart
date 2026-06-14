part of 'command.dart';

/// Moves a feature to [origin], capturing its previous position for undo.
final class MoveFeatureCommand extends Command {
  MoveFeatureCommand(this.id, this.origin);

  final FeatureId id;
  final Offset origin;
  Offset? _previousOrigin;

  @override
  void apply(Document document) {
    final feature = document.featureById(id);
    if (feature == null) return;

    _previousOrigin ??= feature.origin;
    feature.moveTo(origin);
  }

  @override
  void undo(Document document) {
    final previousOrigin = _previousOrigin;
    if (previousOrigin == null) return;

    document.featureById(id)?.moveTo(previousOrigin);
  }

  @override
  Command clone() => MoveFeatureCommand(id, origin)
    .._previousOrigin = _previousOrigin;
}
