import 'dart:ui';

import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/label_layout.dart';
import 'package:squiggle_flutter/theme/document_colors.dart';

export 'package:squiggle_flutter/theme/document_colors.dart'
    show defaultNewTextWidth;

/// Layout of an empty text feature created at [origin], styled by
/// [configureKind] exactly as [newTextFeatureAt] would style it.
LabelLayout newTextLayoutAt(
  Offset origin, {
  void Function(FeatureKindText)? configureKind,
}) {
  final feature = newTextFeatureAt(origin, '', configureKind: configureKind);
  return (feature.kind as FeatureKindText).labelLayout(feature);
}

Feature newTextFeatureAt(
  Offset origin,
  String contents, {
  void Function(FeatureKindText)? configureKind,
}) {
  final kind = FeatureKindText(contents, strokeColor: defaultNewTextFillColor);
  configureKind?.call(kind);
  final size = kind.measureContents(
    width: defaultNewTextWidth,
    fontSize: kind.fontSize,
  );
  return Feature(origin: origin, size: size, kind: kind);
}
