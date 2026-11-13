import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/label_layout.dart';

mixin LabelCapable {
  String get label;
  set label(String value);

  void setLabel(Feature feature, String value) => label = value;

  /// Where and how the label is typeset; drives painting and inline editing.
  LabelLayout labelLayout(Feature feature);
}
