import 'dart:ui';

import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import 'command.dart';

/// Replaces text contents on a [FeatureKindText] feature, refitting font size
/// to the existing bounds. Captures previous kind and size for undo.
final class UpdateTextContentsCommand extends Command {
  UpdateTextContentsCommand({required this.featureId, required this.contents});

  final FeatureId featureId;
  final String contents;
  FeatureKindText? _previousKind;
  Size? _previousSize;

  @override
  void redo(Document document) {
    final feature = document.featureById(featureId);
    if (feature == null) return;

    final textKind = feature.kind;
    if (textKind is! FeatureKindText) return;

    _previousKind ??= textKind;
    _previousSize ??= feature.size;

    final bounds = feature.bounds();
    final newKind = FeatureKindText(
      contents,
      fontSize: textKind.fontSize,
      horizontalAlignment: textKind.horizontalAlignment,
      verticalAlignment: textKind.verticalAlignment,
      strokeColor: textKind.strokeColor,
      fillColor: textKind.fillColor,
      strokeWidth: textKind.strokeWidth,
    ).fittedToBounds(width: bounds.width, height: bounds.height);
    feature.setKind(newKind);
  }

  @override
  void undo(Document document) {
    final previousKind = _previousKind;
    final previousSize = _previousSize;
    if (previousKind == null || previousSize == null) return;

    final feature = document.featureById(featureId);
    if (feature == null) return;
    feature.setKind(previousKind, newSize: previousSize);
  }
}
