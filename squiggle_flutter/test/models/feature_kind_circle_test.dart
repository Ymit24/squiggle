import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  group('FeatureKindCircle serde', () {
    final content = {
      'type': 'circle',
      'strokeColor': 0xFF112233,
      'fillColor': 0xFF445566,
      'strokeWidth': 3.5,
    };

    test('fromDataModel preserves style fields', () {
      final kind = FeatureKindCircle.fromDataModel(content);
      expect(kind.strokeColor.toARGB32(), 0xFF112233);
      expect(kind.fillColor.toARGB32(), 0xFF445566);
      expect(kind.strokeWidth, 3.5);
    });

    test('toDataModel emits type and style fields', () {
      const kind = FeatureKindCircle(
        strokeColor: Color(0xFF112233),
        fillColor: Color(0xFF445566),
        strokeWidth: 3.5,
      );
      expect(kind.toDataModel(), content);
    });

    test('round trip preserves style fields', () {
      final decoded = FeatureKindCircle.fromDataModel(content);
      final roundTripped = FeatureKindCircle.fromDataModel(
        decoded.toDataModel(),
      );
      expect(roundTripped.strokeColor, decoded.strokeColor);
      expect(roundTripped.fillColor, decoded.fillColor);
      expect(roundTripped.strokeWidth, decoded.strokeWidth);
    });
  });
}
