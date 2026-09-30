import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_kinds/inspector_field.dart';

void main() {
  test('byKeyForFeatures groups fields and merges values and callbacks', () {
    final firstKind = FeatureKindCircle(strokeWidth: 1);
    final secondKind = FeatureKindCircle(strokeWidth: 3);
    final features = [
      Feature(origin: Offset.zero, size: const Size(10, 10), kind: firstKind),
      Feature(origin: Offset.zero, size: const Size(20, 20), kind: secondKind),
    ];

    final fields = InspectorField.byKeyForFeatures(features);

    expect(fields.keys, {
      'strokeColor',
      'fillColor',
      'strokeWidth',
      'fontSize',
      'verticalAlignment',
      'horizontalAlignment',
    });
    expect(fields['strokeWidth']!.values, [1, 3]);
    expect(fields['strokeWidth']!.isMixed, isTrue);

    fields['strokeWidth']!.apply(5.0);
    expect(firstKind.strokeWidth, 5);
    expect(secondKind.strokeWidth, 5);
  });
}
