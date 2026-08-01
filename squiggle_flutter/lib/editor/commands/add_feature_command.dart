import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

import 'command.dart';

/// Adds a feature to the document, assigning an id when [feature] has [noId].
final class AddFeatureCommand extends Command {
  const AddFeatureCommand(this.feature);

  final Feature feature;

  @override
  void redo(Document document) {
    document.addFeature(feature);
  }

  @override
  void undo(Document document) {
    document.removeFeature(feature.id);
  }
}
