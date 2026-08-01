import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import 'command.dart';

/// Removes the features identified by [ids], snapshotting them for undo.
final class RemoveFeaturesCommand extends Command {
  RemoveFeaturesCommand(this.ids);

  final List<FeatureId> ids;
  List<Feature>? _removedFeatures;

  @override
  void redo(Document document) {
    _removedFeatures = [
      for (final id in ids)
        if (document.featureById(id) case final feature?) feature.copyWith(),
    ];
    document.removeFeatures(ids);
  }

  @override
  void undo(Document document) {
    for (final feature in _removedFeatures ?? const []) {
      document.addFeature(feature);
    }
  }
}
