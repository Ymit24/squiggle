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
  Command clone() =>
      MoveFeatureCommand(id, origin).._previousOrigin = _previousOrigin;
}

/// Moves a group of features as one undoable edit.
final class MoveFeaturesCommand extends Command {
  MoveFeaturesCommand(this.origins, {Map<FeatureId, Offset>? previousOrigins})
    : _previousOrigins = previousOrigins == null
          ? null
          : Map<FeatureId, Offset>.of(previousOrigins);

  final Map<FeatureId, Offset> origins;
  Map<FeatureId, Offset>? _previousOrigins;

  @override
  void apply(Document document) {
    _previousOrigins ??= {
      for (final id in origins.keys)
        if (document.featureById(id) case final feature?) id: feature.origin,
    };

    for (final entry in origins.entries) {
      document.featureById(entry.key)?.moveTo(entry.value);
    }
  }

  @override
  void undo(Document document) {
    final previousOrigins = _previousOrigins;
    if (previousOrigins == null) return;

    for (final entry in previousOrigins.entries) {
      document.featureById(entry.key)?.moveTo(entry.value);
    }
  }

  @override
  Command clone() => MoveFeaturesCommand(
    Map<FeatureId, Offset>.of(origins),
    previousOrigins: _previousOrigins,
  );
}
