part of 'feature_kind.dart';

final class FeatureKindText extends FeatureKind with LabelCapable {
  FeatureKindText(
    this.label, {
    this.fontSize = defaultFontSize,
    this.horizontalAlignment = TextHorizontalAlignment.left,
    this.verticalAlignment = TextVerticalAlignment.top,
    this.strokeColor = defaultFeatureStrokeColor,
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
        // Older text features stored separate fill and outline colors. The
        // outline color now supplies the single text color.
        strokeColor: _colorFromDataModel(
          content,
          content.containsKey('strokeColor') ? 'strokeColor' : 'fillColor',
        ),
      );

  @override
  Map<String, dynamic> toDataModel() {
    return {
      'type': 'text',
      'contents': label,
      'fontSize': fontSize,
      'horizontalAlignment': horizontalAlignment.name,
      'verticalAlignment': verticalAlignment.name,
      'strokeColor': strokeColor.toARGB32(),
    };
  }

  @override
  FeatureKindText clone() => FeatureKindText(
    label,
    fontSize: fontSize,
    horizontalAlignment: horizontalAlignment,
    verticalAlignment: verticalAlignment,
    strokeColor: strokeColor,
  );

  Color strokeColor;

  @override
  String label;

  double fontSize;
  TextHorizontalAlignment horizontalAlignment;
  TextVerticalAlignment verticalAlignment;

  Size measureContents({required double width, required double fontSize}) =>
      text_painter.measureText(
        label.isEmpty ? ' ' : label,
        width: width,
        fontSize: fontSize,
        horizontalAlignment: horizontalAlignment,
      );

  double? fontSizeFillingBounds({
    required double width,
    required double height,
  }) => text_painter.fontSizeFillingBounds(
    label,
    width: width,
    height: height,
    horizontalAlignment: horizontalAlignment,
  );

  /// Sets [feature] to [fontSize] and a height measured from [label].
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
  void setLabel(Feature feature, String value) {
    label = value;
    feature.size = measureContents(width: feature.width, fontSize: fontSize);
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
    if (label.isNotEmpty) {
      fontSize =
          fontSizeFillingBounds(width: clampedWidth, height: clampedHeight) ??
          text_painter.kMinTextFontSize;
    }
  }

  @override
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
    text_painter.paintText(
      canvas,
      label,
      feature.localBounds(),
      fontSize: fontSize,
      fillColor: strokeColor,
      horizontalAlignment: horizontalAlignment,
      verticalAlignment: verticalAlignment,
      clipToBounds: false,
    );
  }

  @override
  Iterable<InspectorField> buildInspectorFields() {
    return [
      InspectorColorField(
        fieldKey: 'strokeColor',
        label: 'Stroke Color',
        value: strokeColor,
        onColorChanged: (color) {
          strokeColor = color;
        },
      ),
      InspectorVerticalTextAlignmentField(
        fieldKey: 'verticalAlignment',
        label: 'Vertical Alignment',
        value: verticalAlignment,
        onTextAlignChanged: (value) {
          verticalAlignment = value;
        },
      ),
      InspectorHorizontalTextAlignmentField(
        fieldKey: 'horizontalAlignment',
        label: 'Horizontal Alignment',
        value: horizontalAlignment,
        onTextAlignChanged: (value) {
          horizontalAlignment = value;
        },
      ),
      InspectorFontSizeField(
        fieldKey: 'fontSize',
        label: 'Font Size',
        value: fontSize,
        onFontSizeChanged: (value) {
          fontSize = value;
        },
      ),
    ];
  }
}
