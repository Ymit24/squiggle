import 'dart:ui';

import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/models/feature_layout.dart';

import 'command.dart';

/// Aligns or distributes features in one undo step.
final class LayoutFeaturesCommand extends Command {
  LayoutFeaturesCommand.align({
    required this.ids,
    required this.alignment,
  }) : distribution = null;

  LayoutFeaturesCommand.distribute({
    required this.ids,
    required this.distribution,
  }) : alignment = null;

  final List<FeatureId> ids;
  final FeatureAlignment? alignment;
  final FeatureDistribution? distribution;
  Map<FeatureId, Offset>? _previousOrigins;

  @override
  void redo(Document document) {
    final offsets = switch ((alignment, distribution)) {
      (final alignment?, null) =>
        computeAlignmentOffsets(document, ids, alignment),
      (null, final distribution?) =>
        computeDistributionOffsets(document, ids, distribution),
      _ => const <FeatureId, Offset>{},
    };
    if (offsets.isEmpty) return;

    _previousOrigins ??= {};
    final targets = <FeatureId, Offset>{};
    for (final entry in offsets.entries) {
      final feature = document.featureById(entry.key);
      if (feature == null) continue;

      _previousOrigins!.putIfAbsent(entry.key, () => feature.origin);
      targets[entry.key] = feature.origin + entry.value;
    }
    if (targets.isNotEmpty) {
      document.moveFeatures(targets);
    }
  }

  @override
  void undo(Document document) {
    final previousOrigins = _previousOrigins;
    if (previousOrigins == null) return;

    document.moveFeatures(previousOrigins);
  }
}
