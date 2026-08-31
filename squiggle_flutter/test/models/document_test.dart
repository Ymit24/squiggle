import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

void main() {
  group('Document.featureAtPoint', () {
    test('returns top-most feature at point', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: const FeatureKindRectangle(),
        ),
        Feature(
          origin: const Offset(50, 50),
          size: const Size(100, 100),
          kind: const FeatureKindRectangle(),
        ),
      ]);

      final hit = doc.featureAtPoint(const Offset(75, 75));

      expect(hit, isNotNull);
      expect(hit!.origin, const Offset(50, 50));
    });

    test('returns null when no feature contains point', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(50, 50),
          kind: const FeatureKindRectangle(),
        ),
      ]);

      expect(doc.featureAtPoint(const Offset(200, 200)), isNull);
    });
  });

  group('Document mutations', () {
    test('addFeature assigns an id when feature has noId', () {
      final doc = Document();
      final feature = Feature(
        origin: const Offset(1, 2),
        size: const Size(3, 4),
        kind: const FeatureKindRectangle(),
      );

      doc.addFeature(feature);

      expect(feature.id, isNot(noId));
      expect(doc.features, [feature]);
    });

    test('addFeatures adds multiple features in one change', () {
      final doc = Document();
      final features = [
        Feature(
          origin: const Offset(0, 0),
          size: const Size(10, 10),
          kind: const FeatureKindRectangle(),
        ),
        Feature(
          origin: const Offset(20, 0),
          size: const Size(10, 10),
          kind: const FeatureKindCircle(),
        ),
      ];

      doc.addFeatures(features);

      expect(doc.features, hasLength(2));
      expect(doc.features.every((feature) => feature.id != noId), isTrue);
    });

    test('removeFeature removes by id', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(10, 10),
          kind: const FeatureKindRectangle(),
        ),
      ]);
      final id = doc.features.first.id;

      doc.removeFeature(id);

      expect(doc.features, isEmpty);
    });

    test('moveFeature updates origin and notifies', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(10, 10),
          kind: const FeatureKindRectangle(),
        ),
      ]);
      final id = doc.features.first.id;
      var notified = 0;
      doc.addListener(() => notified++);

      doc.featureById(id)!.moveTo(const Offset(5, 5));
      doc.notifyChanged();

      expect(doc.features.first.origin, const Offset(5, 5));
      expect(notified, 1);
    });

    test('setFeatureBounds updates bounds', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(10, 10),
          kind: const FeatureKindRectangle(),
        ),
      ]);
      final id = doc.features.first.id;

      doc.featureById(id)!.setBounds(const Rect.fromLTWH(1, 2, 20, 30));
      doc.notifyChanged();

      expect(doc.features.first.bounds(), const Rect.fromLTWH(1, 2, 20, 30));
    });

    test('replaceFrom replaces contents and next id', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(10, 10),
          kind: const FeatureKindRectangle(),
        ),
      ]);
      final replacement = Document.fromFeatures([
        Feature(
          origin: const Offset(5, 5),
          size: const Size(20, 20),
          kind: const FeatureKindCircle(),
        ),
        Feature(
          origin: const Offset(30, 30),
          size: const Size(20, 20),
          kind: const FeatureKindCircle(),
        ),
      ]);

      doc.replaceFrom(replacement);

      expect(doc.features, hasLength(2));
      expect(doc.features.first.origin, const Offset(5, 5));
      expect(doc.nextId, greaterThanOrEqualTo(2));
    });
  });
}
