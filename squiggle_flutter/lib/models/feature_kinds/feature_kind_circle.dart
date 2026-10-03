part of 'feature_kind.dart';

final class FeatureKindCircle extends FeatureKind
    with
        StrokeColorCapable,
        FillColorCapable,
        FillTypeCapable,
        StrokeWidthCapable,
        StrokeTypeCapable,
        LabelCapable {
  FeatureKindCircle({
    this.strokeColor = defaultFeatureStrokeColor,
    this.fillColor = defaultFeatureFillColor,
    this.fillType = FillType.solid,
    this.strokeWidth = defaultStrokeWidth,
    this.strokeType = StrokeType.solid,
    this.label = '',
    this.labelFontSize = _labelFontSize,
    this.labelVerticalAlignment = TextVerticalAlignment.center,
    this.labelHorizontalAlignment = TextHorizontalAlignment.center,
  });

  factory FeatureKindCircle.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindCircle(
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        fillColor: _colorFromDataModel(content, 'fillColor'),
        fillType: _fillTypeFromDataModel(content),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
        strokeType: _strokeTypeFromDataModel(content),
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
  Color strokeColor;

  @override
  Color fillColor;

  @override
  FillType fillType;

  @override
  double strokeWidth;

  @override
  StrokeType strokeType;

  @override
  String label;

  double labelFontSize;
  TextVerticalAlignment labelVerticalAlignment = TextVerticalAlignment.center;
  TextHorizontalAlignment labelHorizontalAlignment =
      TextHorizontalAlignment.center;

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'circle',
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'fillType': fillType.name,
    'strokeWidth': strokeWidth,
    'strokeType': strokeType.name,
    'label': label,
    'labelFontSize': labelFontSize,
    'labelVerticalAlignment': labelVerticalAlignment.name,
    'labelHorizontalAlignment': labelHorizontalAlignment.name,
  };

  @override
  FeatureKindCircle clone() => FeatureKindCircle(
    strokeColor: strokeColor,
    fillColor: fillColor,
    fillType: fillType,
    strokeWidth: strokeWidth,
    strokeType: strokeType,
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
    final path = Path()..addOval(bounds);
    paintFill(canvas, path, Paint()..color = fillColor, fillType);
    paintStroke(
      canvas,
      path,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
      strokeType,
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
      InspectorFillTypeField(
        fieldKey: 'fillType',
        label: 'Fill Type',
        value: fillType,
        onTypeChanged: (type) => fillType = type,
      ),
      InspectorStrokeTypeField(
        fieldKey: 'strokeType',
        label: 'Stroke Type',
        value: strokeType,
        onTypeChanged: (type) => strokeType = type,
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
