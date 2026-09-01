import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  group('FeatureKindImage serde', () {
    test('fromDataModel preserves image ID and style fields', () {
      final kind = FeatureKindImage.fromDataModel({
        'type': 'image',
        'imageId': 'image-id',
        'strokeColor': 0xFF112233,
        'fillColor': 0xFF445566,
        'strokeWidth': 3.5,
      });
      expect(kind.imageId, 'image-id');
      expect(kind.strokeColor.toARGB32(), 0xFF112233);
      expect(kind.fillColor.toARGB32(), 0xFF445566);
      expect(kind.strokeWidth, 3.5);
    });

    test('toDataModel emits image ID and style fields', () {
      const kind = FeatureKindImage(
        'image-id',
        strokeColor: Color(0xFF112233),
        fillColor: Color(0xFF445566),
        strokeWidth: 3.5,
      );
      expect(kind.toDataModel(), {
        'type': 'image',
        'imageId': 'image-id',
        'strokeColor': 0xFF112233,
        'fillColor': 0xFF445566,
        'strokeWidth': 3.5,
      });
    });

    test('round trip preserves image ID and style fields', () {
      const kind = FeatureKindImage(
        'image-id',
        strokeColor: Color(0xFF112233),
        fillColor: Color(0xFF445566),
        strokeWidth: 3.5,
      );
      final decoded = FeatureKindImage.fromDataModel(kind.toDataModel());
      expect(decoded.imageId, kind.imageId);
      expect(decoded.strokeColor, kind.strokeColor);
      expect(decoded.fillColor, kind.fillColor);
      expect(decoded.strokeWidth, kind.strokeWidth);
    });
  });

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
