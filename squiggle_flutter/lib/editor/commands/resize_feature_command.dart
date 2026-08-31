import 'dart:ui';

import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import 'command.dart';

/// Resizes a feature to [finalBounds], restoring [initialBounds] on undo.
final class ResizeFeatureCommand extends Command {
  ResizeFeatureCommand({
    required this.id,
    required this.initialBounds,
    required this.finalBounds,
  });

  final FeatureId id;
  final Rect initialBounds;
  final Rect finalBounds;

  @override
  void redo(Document document) {
    final feature = document.featureById(id);
    if (feature == null) return;
    feature.resize(finalBounds);
    document.notifyChanged();
  }

  @override
  void undo(Document document) {
    final feature = document.featureById(id);
    if (feature == null) return;
    feature.resize(initialBounds);
    document.notifyChanged();
  }
}
