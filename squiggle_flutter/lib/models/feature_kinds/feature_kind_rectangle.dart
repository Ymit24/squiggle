part of 'feature_kind.dart';

final class FeatureKindRectangle extends FeatureKind with FeatureKindWithLabel {
  FeatureKindRectangle({super.strokeColor, super.fillColor, super.strokeWidth});

  @override
  String? label;

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
    final bounds = feature.localBounds();
    canvas.drawRect(bounds, Paint()..color = fillColor);
    if (label != null) {
      print("D: rect has label! $label");
      paintLabel(feature, canvas, imageRepository);
    }
    canvas.drawRect(
      bounds,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  // TODO: implement fontSize
  double get fontSize => 36;

  @override
  // TODO: implement horizontalAlignment
  TextHorizontalAlignment get horizontalAlignment =>
      TextHorizontalAlignment.center;

  @override
  // TODO: implement verticalAlignment
  TextVerticalAlignment get verticalAlignment => TextVerticalAlignment.center;
}
