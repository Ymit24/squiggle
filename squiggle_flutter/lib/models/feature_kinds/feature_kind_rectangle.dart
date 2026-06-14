part of 'feature_kind.dart';

final class FeatureKindRectangle extends FeatureKind {
  const FeatureKindRectangle();

  @override
  void paint(Feature feature, Canvas canvas) {
    canvas.drawRect(
      feature.bounds(),
      Paint()..color = const Color(0xFFCDA6F7),
    );
  }
}
