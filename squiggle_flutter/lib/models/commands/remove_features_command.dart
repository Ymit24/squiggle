part of 'command.dart';

/// Removes the features identified by [ids], snapshotting them for undo.
final class RemoveFeaturesCommand extends Command {
  RemoveFeaturesCommand(this.ids);

  final List<FeatureId> ids;
  List<Feature>? _removedFeatures;

  @override
  void apply(Document document) {
    _removedFeatures = [];
    for (final id in ids) {
      final feature = document.featureById(id);
      if (feature != null) {
        _removedFeatures!.add(feature.copyWith());
      }
      final index = document.featureIndexById(id);
      if (index != null) {
        document.features.removeAt(index);
      }
    }
  }

  @override
  void undo(Document document) {
    for (final feature in _removedFeatures ?? const []) {
      document.features.add(feature);
    }
  }

  @override
  Command clone() => RemoveFeaturesCommand(List.of(ids))
    .._removedFeatures = _removedFeatures?.map((f) => f.copyWith()).toList();
}
