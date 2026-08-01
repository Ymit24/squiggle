import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

import 'command.dart';

/// Adds multiple features to the document in one undo step.
final class AddFeaturesCommand extends Command {
  AddFeaturesCommand(this.features);

  final List<Feature> features;

  @override
  void redo(Document document) {
    document.addFeatures(features);
  }

  @override
  void undo(Document document) {
    document.removeFeatures(features.map((feature) => feature.id));
  }
}
