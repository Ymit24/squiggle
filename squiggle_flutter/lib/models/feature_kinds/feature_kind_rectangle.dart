part of 'feature_kind.dart';

final class FeatureKindRectangle extends FeatureKind
    with StrokeColorCapable, FillColorCapable {
  FeatureKindRectangle({
    this.strokeColor = defaultFeatureStrokeColor,
    this.fillColor = defaultFeatureFillColor,
    super.strokeWidth,
  });

  @override
  Color strokeColor;

  @override
  Color fillColor;

  factory FeatureKindRectangle.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindRectangle(
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        fillColor: _colorFromDataModel(content, 'fillColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
      );

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'rectangle',
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'strokeWidth': strokeWidth,
  };

  @override
  FeatureKindRectangle clone() => FeatureKindRectangle(
    strokeColor: strokeColor,
    fillColor: fillColor,
    strokeWidth: strokeWidth,
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
