part of 'command.dart';

/// Updates style fields on the features identified by [ids], snapshotting
/// previous kinds for undo.
///
/// Only non-null style fields are applied.
final class UpdateFeaturesStyleCommand extends Command {
  UpdateFeaturesStyleCommand({
    required this.ids,
    this.strokeColor,
    this.fillColor,
    this.strokeWidth,
    this.fontSize,
  });

  final List<FeatureId> ids;
  final Color? strokeColor;
  final Color? fillColor;
  final double? strokeWidth;
  final double? fontSize;
  Map<FeatureId, FeatureKind>? _previousKinds;

  @override
  void apply(Document document) {
    _previousKinds ??= {};
    for (final id in ids) {
      final feature = document.featureById(id);
      if (feature == null) continue;

      _previousKinds!.putIfAbsent(id, () => feature.kind);
      feature.kind = switch (feature.kind) {
        FeatureKindText() => feature.kind.copyWithStyle(
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          fontSize: fontSize,
        ),
        _ => feature.kind.copyWithStyle(
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
        ),
      };
    }
  }

  @override
  void undo(Document document) {
    final previousKinds = _previousKinds;
    if (previousKinds == null) return;

    for (final entry in previousKinds.entries) {
      document.featureById(entry.key)?.kind = entry.value;
    }
  }

  @override
  Command clone() => UpdateFeaturesStyleCommand(
    ids: List.of(ids),
    strokeColor: strokeColor,
    fillColor: fillColor,
    strokeWidth: strokeWidth,
    fontSize: fontSize,
  ).._previousKinds = _previousKinds == null
      ? null
      : Map.of(_previousKinds!);
}
