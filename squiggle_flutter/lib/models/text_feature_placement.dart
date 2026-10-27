import 'dart:ui';

import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/label_layout.dart';
import 'package:squiggle_flutter/theme/document_colors.dart';

/// Layout of a text feature holding [contents] created at [origin], styled by
/// [configureKind] exactly as [newTextFeatureAt] would style it.
LabelLayout newTextLayoutAt(
  Offset origin, {
  String contents = '',
  double? fixedWidth,
  void Function(FeatureKindText)? configureKind,
}) {
  final feature = newTextFeatureAt(
    origin,
    contents,
    fixedWidth: fixedWidth,
    configureKind: configureKind,
  );
  return (feature.kind as FeatureKindText).labelLayout(feature);
}

/// A new text feature placed at [origin].
///
/// Without [fixedWidth] the text is auto-sized and [origin] is its alignment
/// point, so centered text is centered on it. With [fixedWidth], [origin] is
/// the top-left of a box that wraps at that width.
Feature newTextFeatureAt(
  Offset origin,
  String contents, {
  double? fixedWidth,
  void Function(FeatureKindText)? configureKind,
}) {
  final kind = FeatureKindText(
    contents,
    sizing: fixedWidth == null ? TextSizing.auto : TextSizing.fixedWidth,
    strokeColor: defaultNewTextFillColor,
  );
  configureKind?.call(kind);
  final size = kind.measureContents(fontSize: kind.fontSize, width: fixedWidth);
  final anchorShift = fixedWidth == null
      ? size.width * kind.anchorFraction
      : 0.0;
  return Feature(
    origin: origin - Offset(anchorShift, 0),
    size: size,
    kind: kind,
  );
}
