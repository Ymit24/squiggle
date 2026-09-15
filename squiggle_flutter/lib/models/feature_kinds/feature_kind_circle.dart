part of 'feature_kind.dart';

final class FeatureKindCircle extends FeatureKind
    with StrokeColorCapable, FillColorCapable, StrokeWidthCapable {
  FeatureKindCircle({
    this.strokeColor = defaultFeatureStrokeColor,
    this.fillColor = defaultFeatureFillColor,
    this.strokeWidth = defaultStrokeWidth,
  });

  @override
  Color strokeColor;

  @override
  Color fillColor;

  @override
  double strokeWidth;

  factory FeatureKindCircle.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindCircle(
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        fillColor: _colorFromDataModel(content, 'fillColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
      );

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'circle',
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'strokeWidth': strokeWidth,
  };

  @override
  FeatureKindCircle clone() => FeatureKindCircle(
    strokeColor: strokeColor,
    fillColor: fillColor,
    strokeWidth: strokeWidth,
  );

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
  }
}
