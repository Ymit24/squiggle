import 'dart:ui';

import 'package:squiggle_flutter/models/feature.dart';

class PolylineHandle {
  PolylineHandle({
    required this.feature,
    required this.pointIndex,
    required this.geometry,
  });
  final Feature feature;
  final int pointIndex;
  final Rect geometry;
}
