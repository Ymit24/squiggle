import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/text_alignment.dart';

void main() {
  group('textOriginInBounds', () {
    const bounds = Rect.fromLTWH(10, 20, 100, 80);

    test('top alignment uses top-left corner', () {
      expect(
        textOriginInBounds(
          bounds: bounds,
          textHeight: 24,
          verticalAlignment: TextVerticalAlignment.top,
        ),
        const Offset(10, 20),
      );
    });

    test('center alignment offsets vertically', () {
      expect(
        textOriginInBounds(
          bounds: bounds,
          textHeight: 24,
          verticalAlignment: TextVerticalAlignment.center,
        ),
        const Offset(10, 48),
      );
    });

    test('bottom alignment pins text to bottom edge', () {
      expect(
        textOriginInBounds(
          bounds: bounds,
          textHeight: 24,
          verticalAlignment: TextVerticalAlignment.bottom,
        ),
        const Offset(10, 76),
      );
    });
  });
}
