import 'package:flutter/widgets.dart';

mixin FillColorCapable {
  Color get fillColor;
  set fillColor(Color value);

  bool get hasVisibleFill => fillColor.a > 0;
}
