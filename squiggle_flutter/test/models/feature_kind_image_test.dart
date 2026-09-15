import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  group('FeatureKindImage serde', () {
    test('fromDataModel preserves image ID and stroke fields', () {
      final kind = FeatureKindImage.fromDataModel({
        'type': 'image',
        'imageId': 'image-id',
        'strokeColor': 0xFF112233,
        'fillColor': 0xFF445566,
        'strokeWidth': 3.5,
      });
      expect(kind.imageId, 'image-id');
      expect(kind.strokeColor.toARGB32(), 0xFF112233);
      expect(kind.strokeWidth, 3.5);
    });

    test('toDataModel emits image ID and stroke fields', () {
      final kind = FeatureKindImage(
        'image-id',
        strokeColor: Color(0xFF112233),
        strokeWidth: 3.5,
      );
      expect(kind.toDataModel(), {
        'type': 'image',
        'imageId': 'image-id',
        'strokeColor': 0xFF112233,
        'strokeWidth': 3.5,
      });
    });

    test('round trip preserves image ID and stroke fields', () {
      final kind = FeatureKindImage(
        'image-id',
        strokeColor: Color(0xFF112233),
        strokeWidth: 3.5,
      );
      final decoded = FeatureKindImage.fromDataModel(kind.toDataModel());
      expect(decoded.imageId, kind.imageId);
      expect(decoded.strokeColor, kind.strokeColor);
      expect(decoded.strokeWidth, kind.strokeWidth);
    });
  });

  group('FeatureKindImage', () {
    test('supports stroke color but not fill color', () {
      final kind = FeatureKindImage('img_test.png');

      expect(kind, isA<StrokeColorCapable>());
      expect(kind, isNot(isA<FillColorCapable>()));
    });

    test('has no visible stroke by default', () {
      final kind = FeatureKindImage('img_test.png');

      expect(kind.hasVisibleStroke, isFalse);
    });

    test('stroke fields are mutable', () {
      final kind = FeatureKindImage('img_test.png');
      kind
        ..strokeColor = const Color(0xFFFF0000)
        ..strokeWidth = 4;

      expect(kind.strokeColor, const Color(0xFFFF0000));
      expect(kind.strokeWidth, 4);
    });
  });
}
