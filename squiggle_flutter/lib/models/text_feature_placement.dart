import 'dart:ui';

import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/document_colors.dart';

export 'package:squiggle_flutter/theme/document_colors.dart'
    show defaultNewTextWidth;

Rect newTextBoundsAt(Offset origin) {
  final kind = FeatureKindText('', strokeColor: defaultNewTextFillColor);
  final size = kind.measureContents(
    width: defaultNewTextWidth,
    fontSize: defaultFontSize,
  );
  return Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height);
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
