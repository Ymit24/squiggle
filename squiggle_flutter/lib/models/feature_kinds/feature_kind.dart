import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../feature.dart';

part 'feature_kind_rectangle.dart';
part 'feature_kind_circle.dart';
part 'feature_kind_text.dart';

sealed class FeatureKind {
  const FeatureKind();

  void paint(Feature feature, Canvas canvas);
}
