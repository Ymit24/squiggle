import 'dart:ui';

import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

const defaultNewTextWidth = 200.0;
const defaultNewTextFillColor = Color(0xFFFFFFFF);
const defaultNewTextStrokeColor = Color(0x00000000);

Rect newTextBoundsAt(Offset origin) {
  const kind = FeatureKindText(
    '',
    fillColor: defaultNewTextFillColor,
    strokeColor: defaultNewTextStrokeColor,
  );
  final size = kind.measureContents(
    width: defaultNewTextWidth,
    fontSize: defaultFontSize,
  );
  return Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height);
}

Feature newTextFeatureAt(Offset origin, String contents) {
  final kind = FeatureKindText(
    contents,
    fillColor: defaultNewTextFillColor,
    strokeColor: defaultNewTextStrokeColor,
  );
  final size = kind.measureContents(
    width: defaultNewTextWidth,
    fontSize: defaultFontSize,
  );
  return Feature(origin: origin, size: size, kind: kind);
}
