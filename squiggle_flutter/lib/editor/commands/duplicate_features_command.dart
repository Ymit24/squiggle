import 'dart:ui';

import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import 'command.dart';

/// Clones [sourceIds] in place and restores each original to [originsAtDragStart].
///
/// Used for alt-drag duplication: copies appear where the selection was when
/// alt was pressed; originals snap back to their position at drag start.
final class DuplicateFeaturesCommand extends Command {
  DuplicateFeaturesCommand({
    required this.sourceIds,
    required this.originsAtDragStart,
  });

  final List<FeatureId> sourceIds;
  final Map<FeatureId, Offset> originsAtDragStart;

  List<FeatureId>? _createdIds;
  Map<FeatureId, Offset>? _originsBeforeRestore;

  /// Ids assigned to the clones during the last [redo], in [sourceIds] order.
  List<FeatureId> get createdIds => _createdIds ?? const [];

  @override
  void redo(Document document) {
    _createdIds = [];
    _originsBeforeRestore = {};

    for (final id in sourceIds) {
      final feature = document.featureById(id);
      if (feature == null) continue;

      _originsBeforeRestore![id] = feature.origin;

      final clone = feature.copyWith(id: noId);
      document.addFeature(clone);
      _createdIds!.add(clone.id);

      final restoreOrigin = originsAtDragStart[id];
      if (restoreOrigin != null) {
        feature.origin = restoreOrigin;
        document.notifyChanged();
      }
    }
  }

  @override
  void undo(Document document) {
    for (final id in _createdIds ?? const []) {
      document.removeFeature(id);
    }

    final originsBeforeRestore = _originsBeforeRestore;
    if (originsBeforeRestore != null) {
      var changed = false;
      for (final entry in originsBeforeRestore.entries) {
        final feature = document.featureById(entry.key);
        if (feature != null && feature.origin != entry.value) {
          feature.origin = entry.value;
          changed = true;
        }
      }
      if (changed) document.notifyChanged();
    }
  }
}
