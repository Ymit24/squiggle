part of 'command.dart';

/// Resizes a feature to [bounds], capturing its previous bounds for undo.
final class ResizeFeatureCommand extends Command {
  ResizeFeatureCommand(this.id, this.bounds, {Rect? previousBounds})
    : // Keep the public named argument readable while storing private state.
      // ignore: prefer_initializing_formals
      _previousBounds = previousBounds;

  final FeatureId id;
  final Rect bounds;
  Rect? _previousBounds;

  @override
  void apply(Document document) {
    final feature = document.featureById(id);
    if (feature == null) return;

    _previousBounds ??= feature.bounds();
    feature.setBounds(bounds);
  }

  @override
  void undo(Document document) {
    final previousBounds = _previousBounds;
    if (previousBounds == null) return;

    document.featureById(id)?.setBounds(previousBounds);
  }

  @override
  Command clone() =>
      ResizeFeatureCommand(id, bounds).._previousBounds = _previousBounds;
}
