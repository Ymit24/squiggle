part of 'command.dart';

/// Adds multiple features to the document in one undo step.
final class AddFeaturesCommand extends Command {
  AddFeaturesCommand(this.features);

  final List<Feature> features;
  List<FeatureId>? _assignedIds;

  @override
  void apply(Document document) {
    _assignedIds = [];
    for (final feature in features) {
      if (feature.id == noId) {
        feature.id = document.generateId();
      }
      document.features.add(feature);
      _assignedIds!.add(feature.id);
    }
  }

  @override
  void undo(Document document) {
    for (final id in _assignedIds ?? const []) {
      final index = document.featureIndexById(id);
      if (index != null) {
        document.features.removeAt(index);
      }
    }
  }

  @override
  Command clone() => AddFeaturesCommand(
    features.map((feature) => feature.copyWith()).toList(),
  ).._assignedIds = _assignedIds == null ? null : List.of(_assignedIds!);
}
