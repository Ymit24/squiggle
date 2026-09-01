part of 'feature_kind.dart';

final class FeatureKindRectangle extends FeatureKind {
  const FeatureKindRectangle({
    super.strokeColor,
    super.fillColor,
    super.strokeWidth,
  });

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
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
    final bounds = feature.bounds();
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
