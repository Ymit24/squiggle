part of 'feature_kind.dart';

const kMinTextFontSize = 1.0;
const kMaxTextFontSize = 1000.0;

final class FeatureKindText extends FeatureKind
    with StrokeColorCapable, FillColorCapable, StrokeWidthCapable {
  FeatureKindText(
    this.contents, {
    this.fontSize = defaultFontSize,
    this.horizontalAlignment = TextHorizontalAlignment.left,
    this.verticalAlignment = TextVerticalAlignment.top,
    this.strokeColor = defaultFeatureStrokeColor,
    this.fillColor = defaultFeatureFillColor,
    this.strokeWidth = defaultStrokeWidth,
  });

  factory FeatureKindText.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindText(
        content['contents'] as String,
        fontSize: _doubleFromDataModel(content, 'fontSize'),
        horizontalAlignment: TextHorizontalAlignment.values.byName(
          content['horizontalAlignment'] as String,
        ),
        verticalAlignment: TextVerticalAlignment.values.byName(
          content['verticalAlignment'] as String,
        ),
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        fillColor: _colorFromDataModel(content, 'fillColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
      );

  @override
  Map<String, dynamic> toDataModel() {
    return {
      'type': 'text',
      'contents': contents,
      'fontSize': fontSize,
      'horizontalAlignment': horizontalAlignment.name,
      'verticalAlignment': verticalAlignment.name,
      'strokeColor': strokeColor.toARGB32(),
      'fillColor': fillColor.toARGB32(),
      'strokeWidth': strokeWidth,
    };
  }

  @override
  FeatureKindText clone() => FeatureKindText(
    contents,
    fontSize: fontSize,
    horizontalAlignment: horizontalAlignment,
    verticalAlignment: verticalAlignment,
    strokeColor: strokeColor,
    fillColor: fillColor,
    strokeWidth: strokeWidth,
  );

  String contents;
  @override
  Color strokeColor;
  @override
  Color fillColor;
  @override
  double strokeWidth;
  double fontSize;
  TextHorizontalAlignment horizontalAlignment;
  TextVerticalAlignment verticalAlignment;

  /// Measures wrapped text at [width], returning the supplied width and paragraph height.
  Size measureContents({required double width, required double fontSize}) {
    final paragraph = _layoutTextParagraph(
      contents,
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
  double? fontSizeFillingBounds({
    required double width,
    required double height,
  }) {
    assert(width.isFinite && width > 0);
    assert(height.isFinite && height >= 0);

    bool fits(double size) =>
        measureContents(width: width, fontSize: size).height <= height;

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

  void fitToBounds({required double width, required double height}) {
    if (contents.isEmpty) return;
    fontSize =
        fontSizeFillingBounds(width: width, height: height) ?? kMinTextFontSize;
  }

  /// Sets [feature] to [fontSize] and a height measured from [contents].
  void applySizeFromFontSize(
    Feature feature, {
    required double width,
    required Offset origin,
    required double fontSize,
  }) {
    feature.origin = origin;
    feature.size = measureContents(width: width, fontSize: fontSize);
    this.fontSize = fontSize;
  }

  @override
  void applyBounds(Feature feature, Rect bounds) {
    final clampedWidth = bounds.width < kMinEnvelopeDimension
        ? kMinEnvelopeDimension
        : bounds.width;
    final clampedHeight = bounds.height < kMinEnvelopeDimension
        ? kMinEnvelopeDimension
        : bounds.height;
    feature.origin = bounds.topLeft;
    feature.size = Size(clampedWidth, clampedHeight);
    fitToBounds(width: clampedWidth, height: clampedHeight);
  }

  @override
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
    paintText(
      canvas,
      contents,
      feature.localBounds(),
      fontSize: fontSize,
      fillColor: fillColor,
      strokeColor: strokeColor,
      strokeWidth: strokeWidth,
      horizontalAlignment: horizontalAlignment,
      verticalAlignment: verticalAlignment,
      clipToBounds: false,
    );
  }
}

/// Lays out text identically for measurement and painting.
/// The caller owns and must dispose the returned paragraph.
ui.Paragraph _layoutTextParagraph(
  String text, {
  required double width,
  required double fontSize,
  TextHorizontalAlignment horizontalAlignment = TextHorizontalAlignment.left,
  Paint? foreground,
}) {
  assert(width.isFinite && width > 0);
  assert(fontSize.isFinite && fontSize > 0);

  final builder =
      ui.ParagraphBuilder(
          ui.ParagraphStyle(
            textAlign: horizontalAlignment.textAlign,
            fontSize: fontSize,
            textDirection: TextDirection.ltr,
          ),
        )
        ..pushStyle(ui.TextStyle(fontSize: fontSize, foreground: foreground))
        ..addText(text);
  return builder.build()..layout(ui.ParagraphConstraints(width: width));
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
