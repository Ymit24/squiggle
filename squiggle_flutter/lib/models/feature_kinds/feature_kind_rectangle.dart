part of 'feature_kind.dart';

final class FeatureKindRectangle extends FeatureKind {
  const FeatureKindRectangle({
    super.strokeColor,
    super.fillColor,
    super.strokeWidth,
  });

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
