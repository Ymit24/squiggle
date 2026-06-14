import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../feature.dart';

part 'feature_kind_rectangle.dart';
part 'feature_kind_circle.dart';
part 'feature_kind_text.dart';

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
    };
  }

  void paint(Feature feature, Canvas canvas);
}
