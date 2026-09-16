import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  group('FeatureKindRectangle serde', () {
    final content = {
      'type': 'rectangle',
      'strokeColor': 0xFF112233,
      'fillColor': 0xFF445566,
      'strokeWidth': 3.5,
      'label': 'Hello rectangle',
    };

    test('fromDataModel preserves label and style fields', () {
      final kind = FeatureKindRectangle.fromDataModel(content);
      expect(kind.label, 'Hello rectangle');
      expect(kind.strokeColor.toARGB32(), 0xFF112233);
      expect(kind.fillColor.toARGB32(), 0xFF445566);
      expect(kind.strokeWidth, 3.5);
    });

    test('toDataModel emits type, label, and style fields', () {
      final kind = FeatureKindRectangle(
        strokeColor: Color(0xFF112233),
        fillColor: Color(0xFF445566),
        strokeWidth: 3.5,
        label: 'Hello rectangle',
      );
      expect(kind.toDataModel(), content);
    });

    test('round trip preserves label and style fields', () {
      final decoded = FeatureKindRectangle.fromDataModel(content);
      final roundTripped = FeatureKindRectangle.fromDataModel(
        decoded.toDataModel(),
      );
      expect(roundTripped.label, decoded.label);
      expect(roundTripped.strokeColor, decoded.strokeColor);
      expect(roundTripped.fillColor, decoded.fillColor);
      expect(roundTripped.strokeWidth, decoded.strokeWidth);
    });

    test('clone preserves label and style fields', () {
      final original = FeatureKindRectangle.fromDataModel(content);
      final clone = original.clone();

      expect(clone.label, original.label);
      expect(clone.strokeColor, original.strokeColor);
      expect(clone.fillColor, original.fillColor);
      expect(clone.strokeWidth, original.strokeWidth);
    });

    test('defaults to an empty label', () {
      expect(FeatureKindRectangle().label, isEmpty);
    });
  });

  group('setLabel', () {
    test('grows height when wrapped label would overflow', () {
      final kind = FeatureKindRectangle();
      final feature = Feature(
        origin: const Offset(10, 20),
        size: const Size(80, 20),
        kind: kind,
      );

      kind.setLabel(feature, 'a long rectangle label that needs many lines');

      expect(feature.origin, const Offset(10, 20));
      expect(feature.width, 80);
      expect(feature.height, greaterThan(20));
    });

    test('does not shrink height when label fits or is empty', () {
      final kind = FeatureKindRectangle();
      final feature = Feature(
        origin: Offset.zero,
        size: const Size(200, 200),
        kind: kind,
      );

      kind.setLabel(feature, 'short');
      expect(feature.height, 200);
      kind.setLabel(feature, '');
      expect(feature.height, 200);
    });
  });
}
