part of 'command.dart';

/// Adds a feature to the document, assigning an id when [feature] has [noId].
final class AddFeatureCommand extends Command {
  const AddFeatureCommand(this.feature);

  final Feature feature;

  @override
  void apply(Document document) {
    if (feature.id == noId) {
      feature.id = document.generateId();
    }
    document.features.add(feature);
  }

  @override
  void undo(Document document) {
    final index = document.featureIndexById(feature.id);
    if (index != null) {
      document.features.removeAt(index);
    }
  }

  @override
  Command clone() => AddFeatureCommand(feature.copyWith());
}
