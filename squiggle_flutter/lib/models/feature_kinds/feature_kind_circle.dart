part of 'feature_kind.dart';

final class FeatureKindCircle extends FeatureKind {
  const FeatureKindCircle();

  @override
  void paint(Feature feature, Canvas canvas) {
    canvas.drawOval(
      feature.bounds(),
      Paint()..color = const Color(0xFFF38BA8),
    );
  }
}
