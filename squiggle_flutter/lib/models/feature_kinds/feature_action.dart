import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/models/feature.dart';

/// A one-off command a feature kind offers for one of its features, such as
/// closing a line. Actions with the same [key] run together for a selection.
class FeatureAction {
  const FeatureAction({
    required this.key,
    required this.label,
    required this.icon,
    required this.run,
  });

  final String key;
  final String label;
  final IconData icon;
  final VoidCallback run;

  /// The actions every one of [features] offers, grouped by [key].
  static List<List<FeatureAction>> sharedBy(List<Feature> features) {
    final byKey = <String, List<FeatureAction>>{};
    for (final feature in features) {
      for (final action in feature.kind.buildActions(feature)) {
        (byKey[action.key] ??= []).add(action);
      }
    }
    return [
      for (final group in byKey.values)
        if (group.length == features.length) group,
    ];
  }
}
