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
      final kind = FeatureKindImage(
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
      final kind = FeatureKindImage(
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
      final kind = FeatureKindImage('img_test.png');

      expect(kind.hasVisibleStroke, isFalse);
    });

    test('has no visible fill', () {
      final kind = FeatureKindImage(
        'img_test.png',
        fillColor: Color(0xFFFFFFFF),
      );

      expect(kind.hasVisibleFill, isFalse);
    });

    test('style fields are mutable while fill remains invisible', () {
      final kind = FeatureKindImage('img_test.png');
      kind
        ..strokeColor = const Color(0xFFFF0000)
        ..fillColor = const Color(0xFF00FF00)
        ..strokeWidth = 4;

      expect(kind.strokeColor, const Color(0xFFFF0000));
      expect(kind.strokeWidth, 4);
      expect(kind.fillColor, const Color(0xFF00FF00));
      expect(kind.hasVisibleFill, isFalse);
    });
  });
}
