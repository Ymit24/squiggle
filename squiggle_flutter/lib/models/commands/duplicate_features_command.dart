part of 'command.dart';

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

  List<Feature>? _clones;
  Map<FeatureId, Offset>? _originsBeforeRestore;

  /// Ids assigned to the clones during [apply], in [sourceIds] order.
  List<FeatureId> get createdIds =>
      _clones?.map((feature) => feature.id).toList() ?? const [];

  @override
  void apply(Document document) {
    _clones = [];
    _originsBeforeRestore = {};

    for (final id in sourceIds) {
      final feature = document.featureById(id);
      if (feature == null) continue;

      _originsBeforeRestore![id] = feature.origin;

      final clone = feature.copyWith(id: noId);
      if (clone.id == noId) {
        clone.id = document.generateId();
      }
      document.features.add(clone);
      _clones!.add(clone);

      final restoreOrigin = originsAtDragStart[id];
      if (restoreOrigin != null) {
        feature.moveTo(restoreOrigin);
      }
    }
  }

  @override
  void undo(Document document) {
    for (final clone in _clones ?? const []) {
      final index = document.featureIndexById(clone.id);
      if (index != null) {
        document.features.removeAt(index);
      }
    }

    final originsBeforeRestore = _originsBeforeRestore;
    if (originsBeforeRestore != null) {
      for (final entry in originsBeforeRestore.entries) {
        document.featureById(entry.key)?.moveTo(entry.value);
      }
    }
  }

  @override
  Command clone() => DuplicateFeaturesCommand(
    sourceIds: List.of(sourceIds),
    originsAtDragStart: Map.of(originsAtDragStart),
  ).._clones = _clones?.map((feature) => feature.copyWith()).toList()
    .._originsBeforeRestore = _originsBeforeRestore == null
        ? null
        : Map.of(_originsBeforeRestore!);
}
