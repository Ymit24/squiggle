part of 'feature_kind.dart';

final class FeatureKindCircle extends FeatureKind {
  const FeatureKindCircle({
    super.strokeColor,
    super.fillColor,
    super.strokeWidth,
  });

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
