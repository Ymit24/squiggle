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
    document.setFeatureBounds(id, finalBounds);
  }

  @override
  void undo(Document document) {
    document.setFeatureBounds(id, initialBounds);
  }
}
