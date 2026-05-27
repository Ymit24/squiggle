import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

void main() {
  group('Document.featureAtPoint', () {
    test('returns top-most feature at point', () {
      final doc = Document.fromFeatures([
        Feature.newRectangle(const Offset(0, 0), const Size(100, 100)),
        Feature.newRectangle(const Offset(50, 50), const Size(100, 100)),
      ]);

      final hit = doc.featureAtPoint(const Offset(75, 75));

      expect(hit, isNotNull);
      expect(hit!.origin, const Offset(50, 50));
    });

    test('returns null when no feature contains point', () {
      final doc = Document.fromFeatures([
        Feature.newRectangle(const Offset(0, 0), const Size(50, 50)),
      ]);

      expect(doc.featureAtPoint(const Offset(200, 200)), isNull);
    });
  });
}
