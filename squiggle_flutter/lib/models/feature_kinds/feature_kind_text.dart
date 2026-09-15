part of 'feature_kind.dart';

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

  Size measureContents({required double width, required double fontSize}) =>
      text_painter.measureText(
        contents,
        width: width,
        fontSize: fontSize,
        horizontalAlignment: horizontalAlignment,
      );

  double? fontSizeFillingBounds({
    required double width,
    required double height,
  }) => text_painter.fontSizeFillingBounds(
    contents,
    width: width,
    height: height,
    horizontalAlignment: horizontalAlignment,
  );

  void fitToBounds({required double width, required double height}) {
    if (contents.isEmpty) return;
    fontSize =
        fontSizeFillingBounds(width: width, height: height) ??
        text_painter.kMinTextFontSize;
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
    text_painter.paintText(
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
