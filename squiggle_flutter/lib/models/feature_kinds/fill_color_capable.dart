import 'package:flutter/widgets.dart';

const double defaultFillOpacity = 1;

mixin FillColorCapable {
  Color get fillColor;
  set fillColor(Color value);

  double get fillOpacity;
  set fillOpacity(double value);

  bool get hasVisibleFill => fillColor.a > 0 && fillOpacity > 0;

  /// Opacity affects only the fill; the stroke keeps its full strength.
  Color get fillPaintColor =>
      fillColor.withValues(alpha: fillColor.a * fillOpacity);
}
