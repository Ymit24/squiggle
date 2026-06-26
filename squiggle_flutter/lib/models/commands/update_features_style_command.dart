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
    this.horizontalAlignment,
    this.verticalAlignment,
  });

  final List<FeatureId> ids;
  final Color? strokeColor;
  final Color? fillColor;
  final double? strokeWidth;
  final double? fontSize;
  final TextHorizontalAlignment? horizontalAlignment;
  final TextVerticalAlignment? verticalAlignment;
  Map<FeatureId, FeatureKind>? _previousKinds;
  Map<FeatureId, Size>? _previousSizes;

  @override
  void apply(Document document) {
    _previousKinds ??= {};
    if (fontSize != null) {
      _previousSizes ??= {};
    }
    for (final id in ids) {
      final feature = document.featureById(id);
      if (feature == null) continue;

      _previousKinds!.putIfAbsent(id, () => feature.kind);
      if (fontSize != null && feature.kind is FeatureKindText) {
        _previousSizes!.putIfAbsent(id, () => feature.size);
      }
      feature.kind = switch (feature.kind) {
        FeatureKindText() => feature.kind.copyWithStyle(
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          fontSize: fontSize,
          horizontalAlignment: horizontalAlignment,
          verticalAlignment: verticalAlignment,
        ),
        _ => feature.kind.copyWithStyle(
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
        ),
      };
      if (fontSize != null && feature.kind is FeatureKindText) {
        final textKind = feature.kind as FeatureKindText;
        textKind.applySizeFromFontSize(
          feature,
          width: feature.size.width,
          origin: feature.origin,
          fontSize: textKind.fontSize,
        );
      }
    }
  }

  @override
  void undo(Document document) {
    final previousKinds = _previousKinds;
    if (previousKinds == null) return;

    for (final entry in previousKinds.entries) {
      document.featureById(entry.key)?.kind = entry.value;
    }

    final previousSizes = _previousSizes;
    if (previousSizes != null) {
      for (final entry in previousSizes.entries) {
        document.featureById(entry.key)?.size = entry.value;
      }
    }
  }

  @override
  Command clone() => UpdateFeaturesStyleCommand(
    ids: List.of(ids),
    strokeColor: strokeColor,
    fillColor: fillColor,
    strokeWidth: strokeWidth,
    fontSize: fontSize,
    horizontalAlignment: horizontalAlignment,
    verticalAlignment: verticalAlignment,
  ).._previousKinds = _previousKinds == null
      ? null
      : Map.of(_previousKinds!)
    .._previousSizes = _previousSizes == null ? null : Map.of(_previousSizes!);
}
