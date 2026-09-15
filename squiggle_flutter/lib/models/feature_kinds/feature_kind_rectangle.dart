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
  });

  @override
  Color strokeColor;

  @override
  Color fillColor;

  @override
  double strokeWidth;

  @override
  String label;

  @override
  void fitToBounds({required double width, required double height}) {}

  factory FeatureKindRectangle.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindRectangle(
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        fillColor: _colorFromDataModel(content, 'fillColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
        label: content['label'],
      );

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'rectangle',
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'strokeWidth': strokeWidth,
    'label': label,
  };

  @override
  FeatureKindRectangle clone() => FeatureKindRectangle(
    strokeColor: strokeColor,
    fillColor: fillColor,
    strokeWidth: strokeWidth,
    label: label,
  );

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
  }
}
