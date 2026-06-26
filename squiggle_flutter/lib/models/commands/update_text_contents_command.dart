part of 'command.dart';

/// Replaces text contents on a [FeatureKindText] feature, refitting font size
/// to the existing bounds. Captures previous kind and size for undo.
final class UpdateTextContentsCommand extends Command {
  UpdateTextContentsCommand(this.featureId, this.contents);

  final FeatureId featureId;
  final String contents;
  FeatureKindText? _previousKind;
  Size? _previousSize;

  @override
  void apply(Document document) {
    final feature = document.featureById(featureId);
    if (feature == null) return;

    final textKind = feature.kind;
    if (textKind is! FeatureKindText) return;

    _previousKind ??= textKind;
    _previousSize ??= feature.size;

    final bounds = feature.bounds();
    feature.kind = FeatureKindText(
      contents,
      fontSize: textKind.fontSize,
      horizontalAlignment: textKind.horizontalAlignment,
      verticalAlignment: textKind.verticalAlignment,
      strokeColor: textKind.strokeColor,
      fillColor: textKind.fillColor,
      strokeWidth: textKind.strokeWidth,
    ).fittedToBounds(width: bounds.width, height: bounds.height);
  }

  @override
  void undo(Document document) {
    final previousKind = _previousKind;
    final previousSize = _previousSize;
    if (previousKind == null || previousSize == null) return;

    final feature = document.featureById(featureId);
    if (feature == null) return;

    feature.kind = previousKind;
    feature.size = previousSize;
  }

  @override
  Command clone() => UpdateTextContentsCommand(featureId, contents)
    .._previousKind = _previousKind
    .._previousSize = _previousSize;
}
