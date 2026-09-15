import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';

Feature polylineFeature({
  Offset origin = Offset.zero,
  Size size = const Size(100, 100),
  List<Offset> localPoints = const [Offset.zero, Offset(100, 100)],
}) {
  return Feature(
    origin: origin,
    size: size,
    kind: FeatureKindPolyline(
      localPoints,
      strokeColor: const Color(0xFFFFFFFF),
    ),
  );
}

Offset worldPoint(Feature feature, int index) {
  final kind = feature.kind as FeatureKindPolyline;
  return feature.origin + kind.localPoints[index];
}

void main() {
  group('FeatureKindPolyline serde', () {
    test('toDataModel emits type and encodes points', () {
      final kind = FeatureKindPolyline([Offset(1.5, -2.5), Offset(10, 20)]);
      expect(kind.toDataModel(), {
        'type': 'polyline',
        'localPoints': [
          {'x': 1.5, 'y': -2.5},
          {'x': 10.0, 'y': 20.0},
        ],
        'strokeColor': kind.strokeColor.toARGB32(),
        'strokeWidth': kind.strokeWidth,
        'startEndCap': LineEndCap.rounded.name,
        'endEndCap': LineEndCap.rounded.name,
      });
    });

    test('toDataModel preserves an empty point list', () {
      final kind = FeatureKindPolyline([]);
      expect(kind.toDataModel()['localPoints'], isEmpty);
    });

    test('round trip preserves points and style fields', () {
      final kind = FeatureKindPolyline(
        [Offset(1.5, -2.5), Offset(10, 20)],
        strokeColor: Color(0xFF112233),
        strokeWidth: 3.5,
        startEndCap: LineEndCap.arrow,
      );
      final decoded = FeatureKindPolyline.fromDataModel(kind.toDataModel());
      expect(decoded.localPoints, kind.localPoints);
      expect(decoded.strokeColor, kind.strokeColor);
      expect(decoded.strokeWidth, kind.strokeWidth);
      expect(decoded.startEndCap, LineEndCap.arrow);
      expect(decoded.endEndCap, LineEndCap.rounded);
    });

    test('missing end caps decode as rounded for existing documents', () {
      final data =
          FeatureKindPolyline([Offset.zero, const Offset(10, 0)]).toDataModel()
            ..remove('startEndCap')
            ..remove('endEndCap');

      final decoded = FeatureKindPolyline.fromDataModel(data);

      expect(decoded.startEndCap, LineEndCap.rounded);
      expect(decoded.endEndCap, LineEndCap.rounded);
    });
  });

  group('FeatureKindPolyline geometry', () {
    test('boundsFor includes stroke padding around centerline points', () {
      final feature = polylineFeature(
        origin: const Offset(10, 20),
        size: const Size(300, 80),
        localPoints: const [Offset.zero, Offset(100, 100)],
      );

      expect(feature.localBounds(), const Rect.fromLTWH(6, 16, 108, 108));
    });

    test('hitTest hits on segment and misses off to the side', () {
      final feature = polylineFeature(
        origin: const Offset(0, 0),
        size: const Size(100, 0),
        localPoints: const [Offset.zero, Offset(100, 0)],
      );

      expect(feature.hitTest(const Offset(50, 0)), isTrue);
      expect(feature.hitTest(const Offset(50, 40)), isFalse);
    });

    test('hitTest includes arrow heads', () {
      final feature = polylineFeature(
        localPoints: const [Offset.zero, Offset(100, 0)],
      );
      (feature.kind as FeatureKindPolyline).endEndCap = LineEndCap.arrow;

      expect(feature.hitTest(const Offset(80, 10)), isTrue);
    });

    test(
      'intersectsRect detects segment overlap and ignores empty envelope gaps',
      () {
        final feature = polylineFeature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          localPoints: const [Offset.zero, Offset(100, 0), Offset(100, 100)],
        );

        expect(
          feature.intersectsRect(const Rect.fromLTWH(40, -5, 20, 10)),
          isTrue,
        );
        expect(
          feature.intersectsRect(const Rect.fromLTWH(10, 50, 20, 20)),
          isFalse,
        );
      },
    );

    test('intersectsRect uses same tolerance as hitTest for near misses', () {
      final feature = polylineFeature(
        origin: const Offset(0, 0),
        size: const Size(100, 0),
        localPoints: const [Offset.zero, Offset(100, 0)],
      );

      expect(feature.hitTest(const Offset(50, 7)), isTrue);
      expect(
        feature.intersectsRect(const Rect.fromLTWH(45, 7, 10, 10)),
        isTrue,
      );
    });
  });

  group('Document.featureAtPoint with polyline', () {
    test('returns polyline when clicking on segment', () {
      final feature = polylineFeature(
        origin: const Offset(0, 0),
        size: const Size(100, 0),
        localPoints: const [Offset.zero, Offset(100, 0)],
      );
      final doc = Document.fromFeatures([feature]);

      final hit = doc.nodeAtPoint(const Offset(50, 0));

      expect(hit, same(feature));
    });
  });

  group('FeatureKindPolyline translation', () {
    test('translates world points and preserves local points', () {
      final doc = Document.fromFeatures([
        polylineFeature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          localPoints: const [Offset.zero, Offset(100, 100)],
        ),
      ]);
      final beforeEnd = worldPoint((doc.nodes.first as Feature), 1);

      doc.nodes.first.origin = const Offset(20, 30);

      final moved = (doc.nodes.first as Feature);
      final kind = moved.kind as FeatureKindPolyline;
      expect(moved.origin, const Offset(20, 30));
      expect(kind.localPoints, const [Offset.zero, Offset(100, 100)]);
      expect(worldPoint(moved, 1), beforeEnd + const Offset(20, 30));
    });
  });

  group('FeatureKindPolyline resize', () {
    test('scales world points proportionally', () {
      final doc = Document.fromFeatures([
        polylineFeature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          localPoints: const [Offset.zero, Offset(100, 100)],
        ),
      ]);
      (doc.nodes.first as Feature).resize(const Rect.fromLTWH(0, 0, 200, 50));

      final resized = (doc.nodes.first as Feature);
      expect(resized.localBounds(), const Rect.fromLTWH(0, 0, 200, 50));
      expect(worldPoint(resized, 0), const Offset(4, 4));
      expect(worldPoint(resized, 1), const Offset(196, 46));
    });
  });

  group('feature_geometry', () {
    test('distanceToSegment returns perpendicular distance', () {
      expect(
        distanceToSegment(
          const Offset(50, 10),
          Offset.zero,
          const Offset(100, 0),
        ),
        10,
      );
    });

    test('envelopeOfPoints enforces minimum dimension', () {
      final envelope = envelopeOfPoints(const [
        Offset(0, 5),
        Offset(100, 5),
      ], strokePadding: 4);

      expect(envelope.width, 108);
      expect(envelope.height, greaterThanOrEqualTo(kMinEnvelopeDimension));
    });
  });
}
