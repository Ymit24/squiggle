import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../feature.dart';
import '../feature_geometry.dart';

part 'feature_kind_rectangle.dart';
part 'feature_kind_circle.dart';
part 'feature_kind_text.dart';
part 'feature_kind_polyline.dart';

sealed class FeatureKind {
  const FeatureKind({
    this.strokeColor = const Color(0xFFFFFFFF),
    this.fillColor = const Color(0xFF000000),
    this.strokeWidth = defaultStrokeWidth,
  });

  final Color strokeColor;
  final Color fillColor;
  final double strokeWidth;

  bool get hasVisibleStroke => strokeColor.a > 0;

  bool get hasVisibleFill => fillColor.a > 0;

  FeatureKind copyWithStyle({
    Color? strokeColor,
    Color? fillColor,
    double? strokeWidth,
    double? fontSize,
  }) {
    return switch (this) {
      FeatureKindRectangle() => FeatureKindRectangle(
        strokeColor: strokeColor ?? this.strokeColor,
        fillColor: fillColor ?? this.fillColor,
        strokeWidth: strokeWidth ?? this.strokeWidth,
      ),
      FeatureKindCircle() => FeatureKindCircle(
        strokeColor: strokeColor ?? this.strokeColor,
        fillColor: fillColor ?? this.fillColor,
        strokeWidth: strokeWidth ?? this.strokeWidth,
      ),
      FeatureKindText(:final contents, fontSize: final currentFontSize) =>
        FeatureKindText(
          contents,
          fontSize: fontSize ?? currentFontSize,
          strokeColor: strokeColor ?? this.strokeColor,
          fillColor: fillColor ?? this.fillColor,
          strokeWidth: strokeWidth ?? this.strokeWidth,
        ),
      FeatureKindPolyline(:final localPoints) => FeatureKindPolyline(
        localPoints,
        strokeColor: strokeColor ?? this.strokeColor,
        fillColor: fillColor ?? this.fillColor,
        strokeWidth: strokeWidth ?? this.strokeWidth,
      ),
    };
  }

  Rect boundsFor(Feature feature) =>
      Rect.fromLTWH(feature.origin.dx, feature.origin.dy, feature.size.width, feature.size.height);

  bool hitTest(Feature feature, Offset worldPoint) =>
      boundsFor(feature).contains(worldPoint);

  bool intersectsRect(Feature feature, Rect rect) =>
      boundsFor(feature).overlaps(rect);

  void applyBounds(Feature feature, Rect bounds) => feature.setBoundsDirect(bounds);

  void paint(Feature feature, Canvas canvas);
}
