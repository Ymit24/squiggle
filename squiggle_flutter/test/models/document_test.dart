import 'dart:ui';

import 'package:data_models/data_models.dart' as data;
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

  group('Document Serde', () {
    group('Decode', () {
      test('Factory fromDataModel works with empty document', () {
        final document = Document.fromDataModel(const data.Document());

        expect(document.features, isEmpty);
        expect(document.nextId, 1);
      });
      test('Factory fromDataModel preserves feature order', () {
        final raw = data.Document(
          nodes: [
            _rawFeature(id: 1, type: 'rectangle'),
            _rawFeature(id: 2, type: 'circle'),
          ],
        );

        final document = Document.fromDataModel(raw);

        expect(document.features[0].id.value, 1);
        expect(document.features[0].kind, isA<FeatureKindRectangle>());
        expect(document.features[1].id.value, 2);
        expect(document.features[1].kind, isA<FeatureKindCircle>());
      });
      test(
        'Factory fromDataModel with non-empty document has correct nextFeatureId',
        () {
          final document = Document.fromDataModel(
            data.Document(
              nodes: [
                _rawFeature(id: 3, type: 'rectangle'),
                _rawFeature(id: 8, type: 'circle'),
              ],
            ),
          );

          expect(document.nextId, 9);
        },
      );
    });
    group('Encode', () {
      test('toDataModel encodes all features', () {
        final document = Document.fromFeatures([
          Feature(
            id: FeatureId.newId(4),
            origin: const Offset(1, 2),
            size: const Size(3, 4),
            kind: const FeatureKindRectangle(),
          ),
          Feature(
            id: FeatureId.newId(7),
            origin: const Offset(5, 6),
            size: const Size(8, 9),
            kind: const FeatureKindCircle(),
          ),
        ]);

        final raw = document.toDataModel();

        expect(raw.nodes, hasLength(2));
        expect((raw.nodes[0] as data.Feature).id, 4);
        expect((raw.nodes[1] as data.Feature).id, 7);
      });
      test('toDataModel preserves feature order', () {
        final document = Document.fromFeatures([
          Feature(
            id: FeatureId.newId(10),
            origin: Offset.zero,
            size: const Size(1, 1),
            kind: const FeatureKindCircle(),
          ),
          Feature(
            id: FeatureId.newId(20),
            origin: Offset.zero,
            size: const Size(1, 1),
            kind: const FeatureKindRectangle(),
          ),
        ]);

        final raw = document.toDataModel();

        expect((raw.nodes[0] as data.Feature).id, 10);
        expect((raw.nodes[1] as data.Feature).id, 20);
      });
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

      doc.featureById(id)!.resize(const Rect.fromLTWH(1, 2, 20, 30));
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

data.Feature _rawFeature({required int id, required String type}) =>
    data.Feature(
      id: id,
      originX: 0,
      originY: 0,
      width: 10,
      height: 20,
      content: {
        'type': type,
        'strokeColor': 0xFF000000,
        'fillColor': 0xFFFFFFFF,
        'strokeWidth': 1.0,
      },
    );
