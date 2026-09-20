part of 'feature_kind.dart';

final class FeatureKindRectangle extends FeatureKind
    with
        StrokeColorCapable,
        FillColorCapable,
        StrokeWidthCapable,
        LabelCapable {
  FeatureKindRectangle({
    this.strokeColor = defaultFeatureStrokeColor,
    this.fillColor = defaultFeatureFillColor,
    this.strokeWidth = defaultStrokeWidth,
    this.label = '',
    this.labelFontSize = _labelFontSize,
    this.labelVerticalAlignment = TextVerticalAlignment.center,
    this.labelHorizontalAlignment = TextHorizontalAlignment.center,
  });

  @override
  Color strokeColor;

  @override
  Color fillColor;

  @override
  double strokeWidth;

  @override
  String label;

  double labelFontSize;
  TextVerticalAlignment labelVerticalAlignment;
  TextHorizontalAlignment labelHorizontalAlignment;

  factory FeatureKindRectangle.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindRectangle(
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        fillColor: _colorFromDataModel(content, 'fillColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
        label: content['label'],
        labelFontSize: _doubleFromDataModel(content, 'labelFontSize'),
        labelVerticalAlignment: TextVerticalAlignment.values.byName(
          content['verticalAlignment'] as String,
        ),
        labelHorizontalAlignment: TextHorizontalAlignment.values.byName(
          content['labelHorizontalAlignment'] as String,
        ),
      );

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'rectangle',
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'strokeWidth': strokeWidth,
    'label': label,
    'labelFontSize': labelFontSize,
    'labelVerticalAlignment': labelVerticalAlignment.index,
    'labelHorizontalAlignment': labelHorizontalAlignment.index,
  };

  @override
  FeatureKindRectangle clone() => FeatureKindRectangle(
    strokeColor: strokeColor,
    fillColor: fillColor,
    strokeWidth: strokeWidth,
    label: label,
  );

  @override
  void setLabel(Feature feature, String value) {
    label = value;
    _growHeightToFitLabel(
      feature,
      value,
      _paddedLabelBounds(feature.localBounds()),
    );
  }

  @override
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
    final bounds = feature.localBounds();
    canvas.drawRect(bounds, Paint()..color = fillColor);
    canvas.drawRect(
      bounds,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    text_painter.paintText(
      canvas,
      label,
      _paddedLabelBounds(bounds),
      fontSize: labelFontSize,
      fillColor: Color.fromARGB(255, 255, 255, 255),
      horizontalAlignment: labelHorizontalAlignment,
      verticalAlignment: labelVerticalAlignment,
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
      InspectorColorField(
        fieldKey: 'fillColor',
        label: 'Fill Color',
        value: fillColor,
        onColorChanged: (color) {
          fillColor = color;
        },
      ),
      InspectorWidthField(
        fieldKey: 'strokeWidth',
        label: 'Stroke Width',
        value: strokeWidth,
        onWidthChanged: (width) {
          strokeWidth = width;
        },
      ),
      InspectorFontSizeField(
        fieldKey: 'fontSize',
        label: 'Font Size',
        value: labelFontSize,
        onFontSizeChanged: (size) {
          labelFontSize = size;
        },
      ),
      InspectorVerticalTextAlignmentField(
        fieldKey: 'verticalAlignment',
        label: 'Vertical Alignment',
        value: labelVerticalAlignment,
        onTextAlignChanged: (alignment) {
          labelVerticalAlignment = alignment;
        },
      ),
      InspectorHorizontalTextAlignmentField(
        fieldKey: 'horizontalAlignment',
        label: 'Horizontal Alignment',
        value: labelHorizontalAlignment,
        onTextAlignChanged: (alignment) {
          labelHorizontalAlignment = alignment;
        },
      ),
    ];
  }
}
