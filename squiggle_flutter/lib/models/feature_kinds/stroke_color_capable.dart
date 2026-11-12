import 'package:flutter/widgets.dart';

mixin StrokeColorCapable {
  Color get strokeColor;
  set strokeColor(Color value);

  bool get hasVisibleStroke => strokeColor.a > 0;
}
