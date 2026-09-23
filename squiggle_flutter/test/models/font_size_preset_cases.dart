import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/font_size_preset.dart';

void main() {
  test('defaultFontSize matches default preset', () {
    expect(defaultFontSize, FontSizePreset.defaultPreset.size);
  });
}
