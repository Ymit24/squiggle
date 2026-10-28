import 'dart:math' as math;
import 'dart:ui';

import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/document_colors.dart';

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
  final kind = FeatureKindText(contents, strokeColor: defaultNewTextFillColor);
  configureKind?.call(kind);
  // The gesture decides the sizing, whatever the brush says.
  kind.sizing = fixedWidth == null ? TextSizing.auto : TextSizing.fixedWidth;
  final width = fixedWidth == null
      ? null
      : math.max(fixedWidth, kind.minWrapWidth);
  final size = kind.measureContents(fontSize: kind.fontSize, width: width);
  final anchorShift = width == null ? size.width * kind.anchorFraction : 0.0;
  return Feature(
    origin: origin - Offset(anchorShift, 0),
    size: size,
    kind: kind,
  );
}
