import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/stroke_width_preset.dart';

void main() {
  test('defaultStrokeWidth matches default preset', () {
    expect(defaultStrokeWidth, StrokeWidthPreset.defaultPreset.width);
  });
}
