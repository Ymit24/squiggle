import 'dart:ui';

import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import 'command.dart';

/// Moves a feature to [origin], restoring [previousOrigin] on undo.
final class MoveFeatureCommand extends Command {
  MoveFeatureCommand(this.id, this.origin, {this.previousOrigin});

  final FeatureId id;
  final Offset origin;
  final Offset? previousOrigin;

  @override
  void redo(Document document) {
    document.moveFeature(id, origin);
  }

  @override
  void undo(Document document) {
    final previousOrigin = this.previousOrigin;
    if (previousOrigin == null) return;
    document.moveFeature(id, previousOrigin);
  }
}

/// Moves a group of features as one undoable edit.
final class MoveFeaturesCommand extends Command {
  MoveFeaturesCommand(this.initialOrigins, this.finalOrigins);

  /// Origins captured before the gesture started.
  final Map<FeatureId, Offset> initialOrigins;

  /// Origins the features were moved to.
  final Map<FeatureId, Offset> finalOrigins;

  @override
  void redo(Document document) {
    document.moveFeatures(finalOrigins);
  }

  @override
  void undo(Document document) {
    document.moveFeatures(initialOrigins);
  }
}
