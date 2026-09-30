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
      'label': 'Hello circle',
      'labelFontSize': 18.0,
      'labelVerticalAlignment': 'top',
      'labelHorizontalAlignment': 'left',
    };

    test('fromDataModel preserves label and style fields', () {
      final kind = FeatureKindCircle.fromDataModel(content);
      expect(kind.label, 'Hello circle');
      expect(kind.strokeColor.toARGB32(), 0xFF112233);
      expect(kind.fillColor.toARGB32(), 0xFF445566);
      expect(kind.strokeWidth, 3.5);
      expect(kind.labelFontSize, 18);
      expect(kind.labelVerticalAlignment, TextVerticalAlignment.top);
      expect(kind.labelHorizontalAlignment, TextHorizontalAlignment.left);
    });

    test('toDataModel emits type, label, and style fields', () {
      final kind = FeatureKindCircle(
        strokeColor: Color(0xFF112233),
        fillColor: Color(0xFF445566),
        strokeWidth: 3.5,
        label: 'Hello circle',
        labelFontSize: 18,
        labelVerticalAlignment: TextVerticalAlignment.top,
        labelHorizontalAlignment: TextHorizontalAlignment.left,
      );
      expect(kind.toDataModel(), content);
    });

    test('round trip preserves label and style fields', () {
      final decoded = FeatureKindCircle.fromDataModel(content);
      final roundTripped = FeatureKindCircle.fromDataModel(
        decoded.toDataModel(),
      );
      expect(roundTripped.label, decoded.label);
      expect(roundTripped.strokeColor, decoded.strokeColor);
      expect(roundTripped.fillColor, decoded.fillColor);
      expect(roundTripped.strokeWidth, decoded.strokeWidth);
      expect(roundTripped.labelFontSize, decoded.labelFontSize);
      expect(
        roundTripped.labelVerticalAlignment,
        decoded.labelVerticalAlignment,
      );
      expect(
        roundTripped.labelHorizontalAlignment,
        decoded.labelHorizontalAlignment,
      );
    });

    test('clone preserves label and style fields', () {
      final original = FeatureKindCircle.fromDataModel(content);
      final clone = original.clone();

      expect(clone.label, original.label);
      expect(clone.strokeColor, original.strokeColor);
      expect(clone.fillColor, original.fillColor);
      expect(clone.strokeWidth, original.strokeWidth);
      expect(clone.labelFontSize, original.labelFontSize);
      expect(clone.labelVerticalAlignment, original.labelVerticalAlignment);
      expect(clone.labelHorizontalAlignment, original.labelHorizontalAlignment);
    });

    test('uses default label styling', () {
      final kind = FeatureKindCircle();

      expect(kind.label, isEmpty);
      expect(kind.labelFontSize, 24);
      expect(kind.labelVerticalAlignment, TextVerticalAlignment.center);
      expect(kind.labelHorizontalAlignment, TextHorizontalAlignment.center);
    });
  });

  group('setLabel', () {
    test('grows height using the inscribed label area', () {
      final kind = FeatureKindCircle();
      final feature = Feature(
        origin: const Offset(10, 20),
        size: const Size(80, 20),
        kind: kind,
      );

      kind.setLabel(feature, 'a long circle label that needs many lines');

      expect(feature.origin, const Offset(10, 20));
      expect(feature.width, 80);
      expect(feature.height, greaterThan(20));
    });

    test('does not shrink height when label fits or is empty', () {
      final kind = FeatureKindCircle();
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
