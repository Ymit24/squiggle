part of '../select_tool_3.dart';

class PolylineHandle {
  final Feature feature;
  final int pointIndex;
  final Rect geometry;

  PolylineHandle({
    required this.feature,
    required this.pointIndex,
    required this.geometry,
  });
}
