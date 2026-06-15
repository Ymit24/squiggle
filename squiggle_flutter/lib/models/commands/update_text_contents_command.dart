part of 'command.dart';

/// Replaces text contents on a [FeatureKindText] feature, re-measuring height
/// while preserving width. Captures previous contents and size for undo.
final class UpdateTextContentsCommand extends Command {
  UpdateTextContentsCommand(this.featureId, this.contents);

  final FeatureId featureId;
  final String contents;
  String? _previousContents;
  Size? _previousSize;

  @override
  void apply(Document document) {
    final feature = document.featureById(featureId);
    if (feature == null) return;

    final textKind = feature.kind;
    if (textKind is! FeatureKindText) return;

    _previousContents ??= textKind.contents;
    _previousSize ??= feature.size;

    final width = feature.size.width;
    final newKind = FeatureKindText(
      contents,
      fontSize: textKind.fontSize,
      strokeColor: textKind.strokeColor,
      fillColor: textKind.fillColor,
      strokeWidth: textKind.strokeWidth,
    );
    final measured = newKind.measureContents(
      width: width,
      fontSize: textKind.fontSize,
    );

    feature.kind = newKind;
    feature.size = measured;
  }

  @override
  void undo(Document document) {
    final previousContents = _previousContents;
    final previousSize = _previousSize;
    if (previousContents == null || previousSize == null) return;

    final feature = document.featureById(featureId);
    if (feature == null) return;

    final textKind = feature.kind;
    if (textKind is! FeatureKindText) return;

    feature.kind = FeatureKindText(
      previousContents,
      fontSize: textKind.fontSize,
      strokeColor: textKind.strokeColor,
      fillColor: textKind.fillColor,
      strokeWidth: textKind.strokeWidth,
    );
    feature.size = previousSize;
  }

  @override
  Command clone() => UpdateTextContentsCommand(featureId, contents)
    .._previousContents = _previousContents
    .._previousSize = _previousSize;
}
