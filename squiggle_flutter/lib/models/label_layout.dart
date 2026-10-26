import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:squiggle_flutter/models/text_alignment.dart';
import 'package:squiggle_flutter/painting/text_painter.dart' as text_painter;

/// How a feature's label is typeset, in its parent's coordinates.
///
/// Both canvas painting and the inline text editor read this, so the rendered
/// text and the edit field cannot disagree about box, size, or alignment.
@immutable
class LabelLayout {
  const LabelLayout({
    required this.bounds,
    required this.fontSize,
    required this.color,
    required this.horizontalAlignment,
    required this.verticalAlignment,
  });

  final Rect bounds;
  final double fontSize;
  final Color color;
  final TextHorizontalAlignment horizontalAlignment;
  final TextVerticalAlignment verticalAlignment;

  LabelLayout shifted(Offset offset) => LabelLayout(
    bounds: bounds.shift(offset),
    fontSize: fontSize,
    color: color,
    horizontalAlignment: horizontalAlignment,
    verticalAlignment: verticalAlignment,
  );

  void paint(Canvas canvas, String text, {bool clipToBounds = true}) =>
      text_painter.paintText(
        canvas,
        text,
        bounds,
        fontSize: fontSize,
        fillColor: color,
        horizontalAlignment: horizontalAlignment,
        verticalAlignment: verticalAlignment,
        clipToBounds: clipToBounds,
      );

  /// Top-left of the text block for [text], honoring vertical alignment.
  Offset textOrigin(String text) => textOriginInBounds(
    bounds: bounds,
    textHeight: text_painter
        .measureText(
          text.isEmpty ? ' ' : text,
          width: bounds.width,
          fontSize: fontSize,
          horizontalAlignment: horizontalAlignment,
        )
        .height,
    verticalAlignment: verticalAlignment,
  );
}
