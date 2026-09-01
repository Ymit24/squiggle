part of 'feature_kind.dart';

final class FeatureKindCircle extends FeatureKind {
  const FeatureKindCircle({
    super.strokeColor,
    super.fillColor,
    super.strokeWidth,
  });

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
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
    final bounds = feature.bounds();
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
