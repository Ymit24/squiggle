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
      expect(kind.label, 'Hello');
      expect(kind.fontSize, 24.5);
      expect(kind.horizontalAlignment, TextHorizontalAlignment.center);
      expect(kind.verticalAlignment, TextVerticalAlignment.bottom);
      expect(kind.strokeColor.toARGB32(), 0xFF112233);
      expect(kind.fillColor.toARGB32(), 0xFF445566);
      expect(kind.strokeWidth, 3.5);
    });

    test('toDataModel emits all text and style fields', () {
      final kind = FeatureKindText(
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
      expect(result.label, decoded.label);
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

  group('setLabel', () {
    test('preserves width and font size while fitting height to contents', () {
      final kind = FeatureKindText('short', fontSize: 24);
      final feature = Feature(
        origin: const Offset(10, 20),
        size: const Size(100, 200),
        kind: kind,
      );

      kind.setLabel(feature, 'a long line that wraps across several lines');

      expect(feature.origin, const Offset(10, 20));
      expect(feature.width, 100);
      expect(
        feature.height,
        kind.measureContents(width: 100, fontSize: 24).height,
      );
      expect(kind.fontSize, 24);
    });

    test('empty content has the height of one line', () {
      final kind = FeatureKindText('text', fontSize: 24);
      final feature = Feature(
        origin: Offset.zero,
        size: const Size(100, 200),
        kind: kind,
      );

      kind.setLabel(feature, '');

      expect(feature.height, greaterThan(0));
      expect(
        feature.height,
        kind.measureContents(width: 100, fontSize: 24).height,
      );
    });
  });
}
