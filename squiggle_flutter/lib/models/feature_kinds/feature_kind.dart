import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/document_colors.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

import '../feature.dart';
import '../feature_geometry.dart';
import '../text_alignment.dart';

part 'feature_kind_rectangle.dart';
part 'feature_kind_circle.dart';
part 'feature_kind_text.dart';
part 'feature_kind_polyline.dart';
part 'feature_kind_image.dart';

sealed class FeatureKind {
  const FeatureKind({
    this.strokeColor = defaultFeatureStrokeColor,
    this.fillColor = defaultFeatureFillColor,
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
    TextHorizontalAlignment? horizontalAlignment,
    TextVerticalAlignment? verticalAlignment,
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
      FeatureKindText(
        :final contents,
        fontSize: final currentFontSize,
        horizontalAlignment: final currentHorizontalAlignment,
        verticalAlignment: final currentVerticalAlignment,
      ) =>
        FeatureKindText(
          contents,
          fontSize: fontSize ?? currentFontSize,
          horizontalAlignment:
              horizontalAlignment ?? currentHorizontalAlignment,
          verticalAlignment: verticalAlignment ?? currentVerticalAlignment,
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
      FeatureKindImage(:final imageId) => FeatureKindImage(
        imageId,
        strokeColor: strokeColor ?? this.strokeColor,
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

  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository);
}
