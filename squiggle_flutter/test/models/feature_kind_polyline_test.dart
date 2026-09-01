import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/commands/commands.dart';
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
      fillColor: const Color(0xFF89B4FA),
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
      const kind = FeatureKindPolyline([Offset(1.5, -2.5), Offset(10, 20)]);
      expect(kind.toDataModel(), {
        'type': 'polyline',
        'localPoints': [
          {'x': 1.5, 'y': -2.5},
          {'x': 10.0, 'y': 20.0},
        ],
        'strokeColor': kind.strokeColor.toARGB32(),
        'fillColor': kind.fillColor.toARGB32(),
        'strokeWidth': kind.strokeWidth,
      });
    });

    test('toDataModel preserves an empty point list', () {
      const kind = FeatureKindPolyline([]);
      expect(kind.toDataModel()['localPoints'], isEmpty);
    });

    test('round trip preserves points and style fields', () {
      const kind = FeatureKindPolyline(
        [Offset(1.5, -2.5), Offset(10, 20)],
        strokeColor: Color(0xFF112233),
        fillColor: Color(0xFF445566),
        strokeWidth: 3.5,
      );
      final decoded = FeatureKindPolyline.fromDataModel(kind.toDataModel());
      expect(decoded.localPoints, kind.localPoints);
      expect(decoded.strokeColor, kind.strokeColor);
      expect(decoded.fillColor, kind.fillColor);
      expect(decoded.strokeWidth, kind.strokeWidth);
    });
  });

  group('FeatureKindPolyline geometry', () {
    test('boundsFor includes stroke padding around centerline points', () {
      final feature = polylineFeature(
        origin: const Offset(10, 20),
        size: const Size(300, 80),
        localPoints: const [Offset.zero, Offset(100, 100)],
      );

      expect(feature.bounds(), const Rect.fromLTWH(2, 12, 116, 116));
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

      expect(feature.hitTest(const Offset(50, 10)), isTrue);
      expect(
        feature.intersectsRect(const Rect.fromLTWH(45, 8, 10, 10)),
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

      final hit = doc.featureAtPoint(const Offset(50, 0));

      expect(hit, same(feature));
    });
  });

  group('MoveFeatureCommand with polyline', () {
    test('translates world points and preserves local points', () {
      final doc = Document.fromFeatures([
        polylineFeature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          localPoints: const [Offset.zero, Offset(100, 100)],
        ),
      ]);
      final id = doc.features.first.id;
      final beforeEnd = worldPoint(doc.features.first, 1);

      CommandHistory(
        document: doc,
      ).execute(MoveFeatureCommand(id, const Offset(20, 30)));

      final moved = doc.features.first;
      final kind = moved.kind as FeatureKindPolyline;
      expect(moved.origin, const Offset(20, 30));
      expect(kind.localPoints, const [Offset.zero, Offset(100, 100)]);
      expect(worldPoint(moved, 1), beforeEnd + const Offset(20, 30));
    });
  });

  group('ResizeFeatureCommand with polyline', () {
    test('scales world points proportionally', () {
      final doc = Document.fromFeatures([
        polylineFeature(
          origin: const Offset(0, 0),
          size: const Size(100, 100),
          localPoints: const [Offset.zero, Offset(100, 100)],
        ),
      ]);
      final id = doc.features.first.id;

      CommandHistory(document: doc).execute(
        ResizeFeatureCommand(
          id: id,
          initialBounds: doc.features.first.bounds(),
          finalBounds: const Rect.fromLTWH(0, 0, 200, 50),
        ),
      );

      final resized = doc.features.first;
      expect(resized.bounds(), const Rect.fromLTWH(0, 0, 200, 50));
      expect(worldPoint(resized, 0), const Offset(8, 8));
      expect(worldPoint(resized, 1), const Offset(192, 42));
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
