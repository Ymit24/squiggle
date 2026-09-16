import 'dart:ui';

import 'package:squiggle_flutter/models/text_alignment.dart';
import 'package:squiggle_flutter/theme/document_colors.dart';

const kMinTextFontSize = 1.0;
const kMaxTextFontSize = 1000.0;

/// Measures wrapped text at [width], returning the supplied width and paragraph height.
Size measureText(
  String text, {
  required double width,
  required double fontSize,
  TextHorizontalAlignment horizontalAlignment = TextHorizontalAlignment.left,
}) {
  final paragraph = _layoutTextParagraph(
    text,
    width: width,
    fontSize: fontSize,
    horizontalAlignment: horizontalAlignment,
  );
  try {
    return Size(width, paragraph.height);
  } finally {
    paragraph.dispose();
  }
}

/// Largest font size, within 0.25 units, whose wrapped layout fits [height].
///
/// Returns null if the minimum size does not fit. This checks paragraph height,
/// not glyph or outline containment; painting can clip any overflow.
double? fontSizeFillingBounds(
  String text, {
  required double width,
  required double height,
  TextHorizontalAlignment horizontalAlignment = TextHorizontalAlignment.left,
}) {
  assert(width.isFinite && width > 0);
  assert(height.isFinite && height >= 0);

  bool fits(double size) =>
      measureText(
        text,
        width: width,
        fontSize: size,
        horizontalAlignment: horizontalAlignment,
      ).height <=
      height;

  var low = kMinTextFontSize;
  var high = kMaxTextFontSize;
  if (!fits(low)) return null;
  if (fits(high)) return high;

  while (high - low > 0.25) {
    final mid = (low + high) / 2;
    if (fits(mid)) {
      low = mid;
    } else {
      high = mid;
    }
  }
  return low;
}

/// Lays out text identically for measurement and painting.
/// The caller owns and must dispose the returned paragraph.
Paragraph _layoutTextParagraph(
  String text, {
  required double width,
  required double fontSize,
  TextHorizontalAlignment horizontalAlignment = TextHorizontalAlignment.left,
  Paint? foreground,
}) {
  assert(width.isFinite && width > 0);
  assert(fontSize.isFinite && fontSize > 0);

  final builder =
      ParagraphBuilder(
          ParagraphStyle(
            textAlign: horizontalAlignment.textAlign,
            fontSize: fontSize,
            textDirection: TextDirection.ltr,
          ),
        )
        ..pushStyle(TextStyle(fontSize: fontSize, foreground: foreground))
        ..addText(text);
  return builder.build()..layout(ParagraphConstraints(width: width));
}

/// Paints wrapped text at a fixed font size in the canvas's current coordinates.
///
/// Null colors omit that pass; zero stroke width disables the outline.
/// [bounds] is the content area; callers supply any desired padding.
void paintText(
  Canvas canvas,
  String text,
  Rect bounds, {
  double fontSize = defaultFontSize,
  Color? fillColor = defaultNewTextFillColor,
  Color? strokeColor,
  double strokeWidth = 1,
  TextHorizontalAlignment horizontalAlignment = TextHorizontalAlignment.center,
  TextVerticalAlignment verticalAlignment = TextVerticalAlignment.center,
  bool clipToBounds = true,
}) {
  assert(bounds.isFinite);
  assert(fontSize.isFinite && fontSize > 0);
  assert(strokeWidth.isFinite && strokeWidth >= 0);
  if (text.isEmpty || bounds.isEmpty) return;

  void paintParagraph(Paint foreground) {
    final paragraph = _layoutTextParagraph(
      text,
      width: bounds.width,
      fontSize: fontSize,
      horizontalAlignment: horizontalAlignment,
      foreground: foreground,
    );
    try {
      canvas.drawParagraph(
        paragraph,
        textOriginInBounds(
          bounds: bounds,
          textHeight: paragraph.height,
          verticalAlignment: verticalAlignment,
        ),
      );
    } finally {
      paragraph.dispose();
    }
  }

  if (clipToBounds) {
    canvas.save();
    canvas.clipRect(bounds);
  }
  try {
    if (strokeColor != null && strokeColor.a > 0 && strokeWidth > 0) {
      paintParagraph(
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = strokeColor,
      );
    }
    if (fillColor != null && fillColor.a > 0) {
      paintParagraph(Paint()..color = fillColor);
    }
  } finally {
    if (clipToBounds) canvas.restore();
  }
}
