import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

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
        'strokeType': 'solid',
        'strokeWidth': kind.strokeWidth,
        'startEndCap': LineEndCap.rounded.name,
        'endEndCap': LineEndCap.rounded.name,
        'isClosed': false,
        'fillColor': kind.fillColor.toARGB32(),
        'fillType': 'solid',
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

  group('FeatureKindPolyline closed shapes', () {
    const triangle = [Offset.zero, Offset(100, 0), Offset(100, 100)];

    Feature closedTriangle({Color fillColor = const Color(0xFF00FF00)}) {
      final feature = polylineFeature(localPoints: triangle);
      final kind = feature.kind as FeatureKindPolyline
        ..fillColor = fillColor
        ..endEndCap = LineEndCap.arrow;
      kind.setClosed(feature, true);
      return feature;
    }

    test('round trip preserves closing and fill', () {
      final kind = FeatureKindPolyline(
        triangle,
        isClosed: true,
        fillColor: const Color(0x8800FF00),
        fillType: FillType.crosshatch,
      );
      final decoded = FeatureKindPolyline.fromDataModel(kind.toDataModel());
      expect(decoded.isClosed, isTrue);
      expect(decoded.fillColor, const Color(0x8800FF00));
      expect(decoded.fillType, FillType.crosshatch);
      expect(decoded.clone().isClosed, isTrue);
    });

    test('older documents decode as open lines', () {
      final data = FeatureKindPolyline(triangle).toDataModel()
        ..remove('isClosed')
        ..remove('fillColor')
        ..remove('fillType');
      final decoded = FeatureKindPolyline.fromDataModel(data);
      expect(decoded.isClosed, isFalse);
      expect(decoded.fillType, FillType.solid);
    });

    test('hit tests the closing edge and filled interior', () {
      final open = polylineFeature(localPoints: triangle);
      final closed = closedTriangle();
      const onClosingEdge = Offset(50, 50);
      const inside = Offset(80, 30);
      expect(open.hitTest(onClosingEdge), isFalse);
      expect(closed.hitTest(onClosingEdge), isTrue);
      expect(closed.hitTest(inside), isTrue);
      expect(
        closedTriangle(fillColor: const Color(0x00000000)).hitTest(inside),
        isFalse,
      );
      expect(closed.hitTest(const Offset(20, 80)), isFalse);
    });

    test('marquee inside a closed shape selects it', () {
      final rect = Rect.fromCenter(
        center: const Offset(80, 30),
        width: 4,
        height: 4,
      );
      expect(
        polylineFeature(localPoints: triangle).intersectsRect(rect),
        false,
      );
      expect(closedTriangle().intersectsRect(rect), isTrue);
    });

    test('closing drops arrow padding from the bounds', () {
      final feature = closedTriangle();
      final kind = feature.kind as FeatureKindPolyline;
      final halfStroke = kind.strokeWidth / 2;
      expect(
        feature.localBounds(),
        const Rect.fromLTRB(0, 0, 100, 100).inflate(halfStroke),
      );
      expect(feature.size, feature.localBounds().size);
    });

    test(
      'inspector offers fill only when closed and end caps only when open',
      () {
        Set<String> keys(Feature feature) => {
          for (final field in feature.kind.buildInspectorFields(
            feature: feature,
          ))
            field.fieldKey,
        };
        final open = polylineFeature(localPoints: triangle);
        expect(keys(open), containsAll(['startEndCap', 'endEndCap']));
        expect(keys(open), isNot(contains('fillColor')));
        final closed = closedTriangle();
        expect(keys(closed), containsAll(['fillColor', 'fillType']));
        expect(keys(closed), isNot(contains('endEndCap')));
        expect({
          for (final field in open.kind.buildInspectorFields()) field.fieldKey,
        }, containsAll(['fillColor', 'fillType', 'startEndCap', 'endEndCap']));
      },
    );
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

      expect(feature.hitTest(const Offset(82, 8.5)), isTrue);
    });

    test('paints the line and solid arrow head with stroke color', () async {
      final feature = polylineFeature(
        origin: const Offset(30, 50),
        localPoints: const [Offset.zero, Offset(100, 0)],
      );
      (feature.kind as FeatureKindPolyline).endEndCap = LineEndCap.arrow;
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      final imageRepository = ImageRepository();
      feature.paint(canvas, imageRepository);
      final picture = recorder.endRecording();
      final image = await picture.toImage(160, 100);
      final pixels = await image.toByteData(format: ImageByteFormat.rawRgba);

      List<int> pixelAt(int x, int y) {
        final offset = (y * image.width + x) * 4;
        return [for (var i = 0; i < 4; i++) pixels!.getUint8(offset + i)];
      }

      expect(pixelAt(80, 50), [0xFF, 0xFF, 0xFF, 0xFF]);
      expect(pixelAt(120, 50), [0xFF, 0xFF, 0xFF, 0xFF]);

      image.dispose();
      picture.dispose();
      imageRepository.dispose();
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
