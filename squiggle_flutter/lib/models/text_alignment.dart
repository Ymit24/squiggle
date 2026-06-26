import 'dart:ui';

import 'package:flutter/widgets.dart';

enum TextHorizontalAlignment {
  left,
  center,
  right;

  TextAlign get textAlign => switch (this) {
    TextHorizontalAlignment.left => TextAlign.left,
    TextHorizontalAlignment.center => TextAlign.center,
    TextHorizontalAlignment.right => TextAlign.right,
  };
}

enum TextVerticalAlignment {
  top,
  center,
  bottom;

  double yOffset({required double boundsHeight, required double textHeight}) =>
      switch (this) {
        TextVerticalAlignment.top => 0,
        TextVerticalAlignment.center => (boundsHeight - textHeight) / 2,
        TextVerticalAlignment.bottom => boundsHeight - textHeight,
      };
}

Offset textOriginInBounds({
  required Rect bounds,
  required double textHeight,
  required TextVerticalAlignment verticalAlignment,
}) {
  return bounds.topLeft.translate(
    0,
    verticalAlignment.yOffset(
      boundsHeight: bounds.height,
      textHeight: textHeight,
    ),
  );
}
