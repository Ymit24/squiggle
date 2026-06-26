part of 'feature_kind.dart';

final class FeatureKindImage extends FeatureKind {
  const FeatureKindImage(
    this.imageId, {
    super.strokeColor,
    super.fillColor = const Color(0x00000000),
    super.strokeWidth,
  });

  final String imageId;

  @override
  bool get hasVisibleFill => false;

  FeatureKindImage copyWith({String? imageId}) {
    return FeatureKindImage(
      imageId ?? this.imageId,
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
    );
  }

  @override
  void paint(
    Feature feature,
    Canvas canvas,
    ImageRepository imageRepository,
  ) {
    final bounds = feature.bounds();
    final image = imageRepository.getCached(imageId);
    if (image != null) {
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        bounds,
        Paint(),
      );
    } else {
      imageRepository.requestImage(imageId);
      canvas.drawRect(
        bounds,
        Paint()..color = const Color(0xFF45475A),
      );
    }

    if (hasVisibleStroke) {
      canvas.drawRect(
        bounds,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth,
      );
    }
  }
}
