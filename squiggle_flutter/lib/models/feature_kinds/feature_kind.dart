import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/painting/text_painter.dart' as text_painter;
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/document_colors.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';

part 'feature_kind_rectangle.dart';
part 'feature_kind_circle.dart';
part 'feature_kind_text.dart';
part 'feature_kind_polyline.dart';
part 'feature_kind_image.dart';

sealed class FeatureKind {
  Map<String, dynamic> toDataModel();

  FeatureKind clone();

  Rect boundsFor(Feature feature) => Rect.fromLTWH(
    feature.origin.dx,
    feature.origin.dy,
    feature.size.width,
    feature.size.height,
  );

  bool hitTest(Feature feature, Offset worldPoint) =>
      boundsFor(feature).contains(worldPoint);

  bool intersectsRect(Feature feature, Rect rect) =>
      boundsFor(feature).overlaps(rect);

  void applyBounds(Feature feature, Rect bounds) => feature.setBounds(bounds);

  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository);
}

mixin StrokeColorCapable {
  Color get strokeColor;
  set strokeColor(Color value);

  bool get hasVisibleStroke => strokeColor.a > 0;
}

mixin FillColorCapable {
  Color get fillColor;
  set fillColor(Color value);

  bool get hasVisibleFill => fillColor.a > 0;
}

mixin StrokeWidthCapable {
  double get strokeWidth;
  set strokeWidth(double value);
}

mixin LabelCapable {
  String get label;
  set label(String value);

  void fitToBounds({required double width, required double height});
}

double _doubleFromDataModel(Map<String, dynamic> content, String key) {
  return (content[key] as num).toDouble();
}

Color _colorFromDataModel(Map<String, dynamic> content, String key) {
  return Color((content[key] as num).toInt());
}

Offset _offsetFromDataModel(Object value) {
  final point = value as Map;
  return Offset((point['x'] as num).toDouble(), (point['y'] as num).toDouble());
}
