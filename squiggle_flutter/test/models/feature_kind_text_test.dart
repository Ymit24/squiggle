import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  group('FeatureKindText serde', () {
    final content = {
      'type': 'text',
      'contents': 'Hello',
      'fontSize': 24.5,
      'horizontalAlignment': 'center',
      'verticalAlignment': 'bottom',
      'strokeColor': 0xFF112233,
      'fillColor': 0xFF445566,
      'strokeWidth': 3.5,
    };

    test('fromDataModel preserves text and style fields', () {
      final kind = FeatureKindText.fromDataModel(content);
      expect(kind.contents, 'Hello');
      expect(kind.fontSize, 24.5);
      expect(kind.horizontalAlignment, TextHorizontalAlignment.center);
      expect(kind.verticalAlignment, TextVerticalAlignment.bottom);
      expect(kind.strokeColor.toARGB32(), 0xFF112233);
      expect(kind.fillColor.toARGB32(), 0xFF445566);
      expect(kind.strokeWidth, 3.5);
    });

    test('toDataModel emits all text and style fields', () {
      const kind = FeatureKindText(
        'Hello',
        fontSize: 24.5,
        horizontalAlignment: TextHorizontalAlignment.center,
        verticalAlignment: TextVerticalAlignment.bottom,
        strokeColor: Color(0xFF112233),
        fillColor: Color(0xFF445566),
        strokeWidth: 3.5,
      );
      expect(kind.toDataModel(), content);
    });

    test('round trip preserves text and style fields', () {
      final decoded = FeatureKindText.fromDataModel(content);
      final result = FeatureKindText.fromDataModel(decoded.toDataModel());
      expect(result.contents, decoded.contents);
      expect(result.fontSize, decoded.fontSize);
      expect(result.horizontalAlignment, decoded.horizontalAlignment);
      expect(result.verticalAlignment, decoded.verticalAlignment);
      expect(result.strokeColor, decoded.strokeColor);
      expect(result.fillColor, decoded.fillColor);
      expect(result.strokeWidth, decoded.strokeWidth);
    });

    test('invalid alignment names throw ArgumentError', () {
      expect(
        () => FeatureKindText.fromDataModel({
          ...content,
          'horizontalAlignment': 'invalid',
        }),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => FeatureKindText.fromDataModel({
          ...content,
          'verticalAlignment': 'invalid',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
