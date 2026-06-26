import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  group('FeatureKindImage', () {
    test('has no visible stroke by default', () {
      const kind = FeatureKindImage('img_test.png');

      expect(kind.hasVisibleStroke, isFalse);
    });

    test('has no visible fill', () {
      const kind = FeatureKindImage(
        'img_test.png',
        fillColor: Color(0xFFFFFFFF),
      );

      expect(kind.hasVisibleFill, isFalse);
    });

    test('copyWithStyle updates stroke but ignores fill', () {
      const kind = FeatureKindImage('img_test.png');
      final updated = kind.copyWithStyle(
        strokeColor: const Color(0xFFFF0000),
        fillColor: const Color(0xFF00FF00),
        strokeWidth: 4,
      );

      expect(updated, isA<FeatureKindImage>());
      final imageKind = updated as FeatureKindImage;
      expect(imageKind.strokeColor, const Color(0xFFFF0000));
      expect(imageKind.strokeWidth, 4);
      expect(imageKind.fillColor, const Color(0x00000000));
      expect(imageKind.hasVisibleFill, isFalse);
    });
  });
}
