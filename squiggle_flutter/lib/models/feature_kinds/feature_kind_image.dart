part of 'feature_kind.dart';

final class FeatureKindImage extends FeatureKind with StrokeColorCapable {
  FeatureKindImage(
    this.imageId, {
    this.strokeColor = transparentStrokeColor,
    super.strokeWidth,
  });

  factory FeatureKindImage.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindImage(
        content['imageId'] as String,
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
      );

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'image',
    'imageId': imageId,
    'strokeColor': strokeColor.toARGB32(),
    'strokeWidth': strokeWidth,
  };

  @override
  FeatureKindImage clone() => FeatureKindImage(
    imageId,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
  );

  String imageId;
  @override
  Color strokeColor;

  @override
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
    final bounds = feature.localBounds();
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
      canvas.drawRect(bounds, Paint()..color = SquiggleColors.surface1);
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
