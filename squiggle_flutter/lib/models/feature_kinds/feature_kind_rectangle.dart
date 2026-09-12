part of 'feature_kind.dart';

final class FeatureKindRectangle extends FeatureKind {
  FeatureKindRectangle({super.strokeColor, super.fillColor, super.strokeWidth});

  void addLabel(Feature feature, String label) {
    labelNode = feature.insert(
      Feature(
        kind: FeatureKindText(label),
        origin: Offset.zero,
        size: feature.size,
      ),
    );
  }

  Feature? labelNode;

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
  void applyBounds(Feature feature, Rect bounds) {
    super.applyBounds(feature, bounds);
    print(
      "D: bounds of feature, ${feature.localBounds()}, bounds of text: ${labelNode?.localBounds()}",
    );
    labelNode?.resize(feature.localBounds().shift(-feature.origin));
  }

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

    if (labelNode != null) {
      canvas.save();
      canvas.translate(feature.origin.dx, feature.origin.dy);
      labelNode!.paint(canvas, imageRepository);
      canvas.restore();
    }
  }
}
