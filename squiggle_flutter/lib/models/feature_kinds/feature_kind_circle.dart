part of 'feature_kind.dart';

final class FeatureKindCircle extends FeatureKind
    with
        StrokeColorCapable,
        FillColorCapable,
        StrokeWidthCapable,
        LabelCapable {
  FeatureKindCircle({
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
  TextVerticalAlignment labelVerticalAlignment = TextVerticalAlignment.center;
  TextHorizontalAlignment labelHorizontalAlignment =
      TextHorizontalAlignment.center;

  factory FeatureKindCircle.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindCircle(
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        fillColor: _colorFromDataModel(content, 'fillColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
        label: content['label'],
        labelFontSize: _doubleFromDataModel(content, 'labelFontSize'),
        labelVerticalAlignment: TextVerticalAlignment.values.byName(
          content['labelVerticalAlignment'] as String,
        ),
        labelHorizontalAlignment: TextHorizontalAlignment.values.byName(
          content['labelHorizontalAlignment'] as String,
        ),
      );

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'circle',
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'strokeWidth': strokeWidth,
    'label': label,
    'labelFontSize': labelFontSize,
    'labelVerticalAlignment': labelVerticalAlignment,
    'labelHorizontalAlignment': labelHorizontalAlignment,
  };

  @override
  FeatureKindCircle clone() => FeatureKindCircle(
    strokeColor: strokeColor,
    fillColor: fillColor,
    strokeWidth: strokeWidth,
    label: label,
    labelFontSize: labelFontSize,
    labelVerticalAlignment: labelVerticalAlignment,
    labelHorizontalAlignment: labelHorizontalAlignment,
  );

  @override
  void setLabel(Feature feature, String value) {
    label = value;
    _growHeightToFitLabel(
      feature,
      value,
      _inscribedLabelBounds(feature.localBounds()),
      outerHeightScale: math.sqrt2,
    );
  }

  @override
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
    final bounds = feature.localBounds();
    canvas.drawOval(bounds, Paint()..color = fillColor);
    canvas.drawOval(
      bounds,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    text_painter.paintText(
      canvas,
      label,
      _inscribedLabelBounds(bounds),
      fontSize: labelFontSize,
      fillColor: Color.fromARGB(255, 255, 255, 255),
      verticalAlignment: labelVerticalAlignment,
      horizontalAlignment: labelHorizontalAlignment,
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
