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
    final feature = document.featureById(id);
    if (feature == null) return;
    feature.moveTo(origin);
    document.notifyChanged();
  }

  @override
  void undo(Document document) {
    final previousOrigin = this.previousOrigin;
    if (previousOrigin == null) return;
    final feature = document.featureById(id);
    if (feature == null) return;
    feature.moveTo(previousOrigin);
    document.notifyChanged();
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
    _moveFeatures(document, finalOrigins);
  }

  @override
  void undo(Document document) {
    _moveFeatures(document, initialOrigins);
  }

  void _moveFeatures(Document document, Map<FeatureId, Offset> origins) {
    var changed = false;
    for (final entry in origins.entries) {
      final feature = document.featureById(entry.key);
      if (feature != null && feature.origin != entry.value) {
        feature.moveTo(entry.value);
        changed = true;
      }
    }
    if (changed) document.notifyChanged();
  }
}
