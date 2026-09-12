import 'dart:ui';

import 'package:data_models/data_models.dart' as data;
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';

void main() {
  group('Document node lookup', () {
    test('requireNodeById returns the node', () {
      final feature = Feature(
        origin: Offset.zero,
        size: const Size(10, 10),
        kind: FeatureKindRectangle(),
      );
      final document = Document()..addNode(feature);

      expect(document.requireNodeById(feature.id), same(feature));
    });

    test('requireNodeById throws when the node does not exist', () {
      final document = Document();

      expect(
        () => document.requireNodeById(NodeId.newId(42)),
        throwsA(
          isA<StateError>().having(
            (error) => error.message,
            'message',
            'Node with id 42 does not exist',
          ),
        ),
      );
    });
  });

  group('Document.nodeAtPoint', () {
    test('returns the top-most root node, including group interiors', () {
      final child = Feature(
        origin: const Offset(10, 20),
        size: const Size(20, 20),
        kind: FeatureKindRectangle(),
      );
      final group = Group(origin: const Offset(100, 200), children: [child]);
      final foreground = Feature(
        origin: const Offset(120, 220),
        size: const Size(20, 20),
        kind: FeatureKindRectangle(),
      );
      final doc = Document()..addNodes([group, foreground]);

      expect(doc.nodeAtPoint(const Offset(115, 225)), same(group));
      expect(doc.nodeAtPoint(const Offset(125, 225)), same(foreground));
      expect(doc.nodeAtPoint(const Offset(15, 25)), isNull);
    });

    test('returns top-most feature at point', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
        ),
        Feature(
          origin: const Offset(50, 50),
          size: const Size(100, 100),
          kind: FeatureKindRectangle(),
        ),
      ]);

      final hit = doc.nodeAtPoint(const Offset(75, 75));

      expect(hit, isNotNull);
      expect(hit!.origin, const Offset(50, 50));
    });

    test('returns null when no feature contains point', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(50, 50),
          kind: FeatureKindRectangle(),
        ),
      ]);

      expect(doc.nodeAtPoint(const Offset(200, 200)), isNull);
    });
  });

  group('Document Serde', () {
    group('Decode', () {
      test('Factory fromDataModel works with empty document', () {
        final document = Document.fromDataModel(
          const data.Document(name: 'Named document'),
        );

        expect(document.nodes, isEmpty);
        expect(document.nextId, 1);
        expect(document.name, 'Named document');
      });
      test('Factory fromDataModel preserves feature order', () {
        final raw = data.Document(
          nodes: [
            _rawFeature(id: 1, type: 'rectangle'),
            _rawFeature(id: 2, type: 'circle'),
          ],
        );

        final document = Document.fromDataModel(raw);

        expect(document.nodes[0].id.value, 1);
        expect(
          (document.nodes[0] as Feature).kind,
          isA<FeatureKindRectangle>(),
        );
        expect(document.nodes[1].id.value, 2);
        expect((document.nodes[1] as Feature).kind, isA<FeatureKindCircle>());
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
            id: NodeId.newId(4),
            origin: const Offset(1, 2),
            size: const Size(3, 4),
            kind: FeatureKindRectangle(),
          ),
          Feature(
            id: NodeId.newId(7),
            origin: const Offset(5, 6),
            size: const Size(8, 9),
            kind: const FeatureKindCircle(),
          ),
        ]);
        document.name = 'Named document';

        final raw = document.toDataModel();

        expect(raw.name, 'Named document');
        expect(raw.nodes, hasLength(2));
        expect((raw.nodes[0] as data.Feature).id, 4);
        expect((raw.nodes[1] as data.Feature).id, 7);
      });
      test('toDataModel preserves feature order', () {
        final document = Document.fromFeatures([
          Feature(
            id: NodeId.newId(10),
            origin: Offset.zero,
            size: const Size(1, 1),
            kind: const FeatureKindCircle(),
          ),
          Feature(
            id: NodeId.newId(20),
            origin: Offset.zero,
            size: const Size(1, 1),
            kind: FeatureKindRectangle(),
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
        kind: FeatureKindRectangle(),
      );

      doc.addNode(feature);

      expect(feature.id, isNot(noId));
      expect(doc.nodes, [feature]);
    });

    test('addFeatures adds multiple features in one change', () {
      final doc = Document();
      final features = [
        Feature(
          origin: const Offset(0, 0),
          size: const Size(10, 10),
          kind: FeatureKindRectangle(),
        ),
        Feature(
          origin: const Offset(20, 0),
          size: const Size(10, 10),
          kind: const FeatureKindCircle(),
        ),
      ];

      doc.addNodes(features);

      expect(doc.nodes, hasLength(2));
      expect(doc.nodes.every((feature) => feature.id != noId), isTrue);
    });

    test('removeFeature removes by id', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(10, 10),
          kind: FeatureKindRectangle(),
        ),
      ]);
      final id = doc.nodes.first.id;

      doc.removeFeature(id);

      expect(doc.nodes, isEmpty);
    });

    test('moveFeature updates origin', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(10, 10),
          kind: FeatureKindRectangle(),
        ),
      ]);
      final id = doc.nodes.first.id;

      doc.featureById(id)!.origin = const Offset(5, 5);

      expect(doc.nodes.first.origin, const Offset(5, 5));
    });

    test('setFeatureBounds updates bounds', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(10, 10),
          kind: FeatureKindRectangle(),
        ),
      ]);
      final id = doc.nodes.first.id;

      doc.featureById(id)!.resize(const Rect.fromLTWH(1, 2, 20, 30));

      expect(doc.nodes.first.localBounds(), const Rect.fromLTWH(1, 2, 20, 30));
    });

    test('replaceFrom replaces contents and next id', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(10, 10),
          kind: FeatureKindRectangle(),
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
      replacement.name = 'Replacement';

      doc.replaceFrom(replacement);

      expect(doc.nodes, hasLength(2));
      expect(doc.name, 'Replacement');
      expect(doc.nodes.first.origin, const Offset(5, 5));
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
