part of 'feature_kind.dart';

final class FeatureKindCircle extends FeatureKind with FeatureKindWithLabel {
  FeatureKindCircle({super.strokeColor, super.fillColor, super.strokeWidth});

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
    final bounds = feature.localBounds();
    canvas.drawOval(bounds, Paint()..color = fillColor);
    if (label != null) {
      paintLabel(feature, canvas, imageRepository);
    }
    canvas.drawOval(
      bounds,
      Paint()
        ..color = strokeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  String? label;

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
