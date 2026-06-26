part of 'command.dart';

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
  void apply(Document document) {
    final offsets = switch ((alignment, distribution)) {
      (final alignment?, null) =>
        computeAlignmentOffsets(document, ids, alignment),
      (null, final distribution?) =>
        computeDistributionOffsets(document, ids, distribution),
      _ => const <FeatureId, Offset>{},
    };
    if (offsets.isEmpty) return;

    _previousOrigins ??= {};
    for (final entry in offsets.entries) {
      final feature = document.featureById(entry.key);
      if (feature == null) continue;

      _previousOrigins!.putIfAbsent(entry.key, () => feature.origin);
      feature.moveTo(feature.origin + entry.value);
    }
  }

  @override
  void undo(Document document) {
    final previousOrigins = _previousOrigins;
    if (previousOrigins == null) return;

    for (final entry in previousOrigins.entries) {
      document.featureById(entry.key)?.moveTo(entry.value);
    }
  }

  @override
  Command clone() {
    if (alignment != null) {
      return LayoutFeaturesCommand.align(
        ids: List.of(ids),
        alignment: alignment!,
      ).._previousOrigins = _previousOrigins == null
          ? null
          : Map.of(_previousOrigins!);
    }

    return LayoutFeaturesCommand.distribute(
      ids: List.of(ids),
      distribution: distribution!,
    ).._previousOrigins = _previousOrigins == null
        ? null
        : Map.of(_previousOrigins!);
  }
}
