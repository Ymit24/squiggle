import 'dart:ui';

import 'package:data_models/data_models.dart' as data;
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

void main() {
  group('Feature Serde', () {
    group('Decode', () {
      test('preserves the feature ID', () {
        expect(Feature.fromDataModel(_rawFeature('rectangle')).id.value, 42);
      });

      test('preserves origin coordinates', () {
        expect(
          Feature.fromDataModel(_rawFeature('rectangle')).origin,
          const Offset(12.5, -8.25),
        );
      });

      test('preserves width and height', () {
        expect(
          Feature.fromDataModel(_rawFeature('rectangle')).size,
          const Size(100.5, 200.25),
        );
      });

      for (final entry in {
        'rectangle': FeatureKindRectangle,
        'circle': FeatureKindCircle,
        'text': FeatureKindText,
        'polyline': FeatureKindPolyline,
        'image': FeatureKindImage,
      }.entries) {
        test('dispatches type ${entry.key}', () {
          expect(
            Feature.fromDataModel(_rawFeature(entry.key)).kind,
            isA<FeatureKind>(),
          );
          expect(
            Feature.fromDataModel(_rawFeature(entry.key)).kind.runtimeType,
            entry.value,
          );
        });
      }

      test('throws FormatException for an unknown feature kind', () {
        expect(
          () => Feature.fromDataModel(_rawFeature('unknown')),
          throwsA(isA<FormatException>()),
        );
      });
    });

    group('Encode', () {
      final features = <Feature>[
        Feature(
          id: FeatureId.newId(42),
          origin: const Offset(12.5, -8.25),
          size: const Size(100.5, 200.25),
          kind: const FeatureKindRectangle(),
        ),
        Feature(
          id: FeatureId.newId(43),
          origin: const Offset(12.5, -8.25),
          size: const Size(100.5, 200.25),
          kind: const FeatureKindCircle(),
        ),
        Feature(
          id: FeatureId.newId(44),
          origin: const Offset(12.5, -8.25),
          size: const Size(100.5, 200.25),
          kind: const FeatureKindText('text'),
        ),
        Feature(
          id: FeatureId.newId(45),
          origin: const Offset(12.5, -8.25),
          size: const Size(100.5, 200.25),
          kind: const FeatureKindPolyline([Offset.zero, Offset(1, 1)]),
        ),
        Feature(
          id: FeatureId.newId(46),
          origin: const Offset(12.5, -8.25),
          size: const Size(100.5, 200.25),
          kind: const FeatureKindImage('image-id'),
        ),
      ];

      test(
        'emits the expected ID',
        () => expect(features.first.toDataModel().id, 42),
      );

      test('emits origin coordinates', () {
        final raw = features.first.toDataModel();
        expect(raw.originX, 12.5);
        expect(raw.originY, -8.25);
      });

      test('emits width and height', () {
        final raw = features.first.toDataModel();
        expect(raw.width, 100.5);
        expect(raw.height, 200.25);
      });

      test('emits a data.Feature', () {
        expect(features.first.toDataModel(), isA<data.Feature>());
      });

      test('uses the correct content type', () {
        expect(
          [
            for (final feature in features)
              feature.toDataModel().content['type'],
          ],
          ['rectangle', 'circle', 'text', 'polyline', 'image'],
        );
      });
    });
  });
}

data.Feature _rawFeature(String type) {
  final content = <String, dynamic>{
    'type': type,
    'strokeColor': 0xFF000000,
    'fillColor': 0xFFFFFFFF,
    'strokeWidth': 1.0,
  };
  if (type == 'text') {
    content.addAll({
      'contents': 'text',
      'fontSize': 16.0,
      'horizontalAlignment': 'left',
      'verticalAlignment': 'top',
    });
  } else if (type == 'polyline') {
    content['localPoints'] = [
      {'x': 0.0, 'y': 0.0},
      {'x': 1.0, 'y': 1.0},
    ];
  } else if (type == 'image') {
    content['imageId'] = 'image-id';
  }
  return data.Feature(
    id: 42,
    originX: 12.5,
    originY: -8.25,
    width: 100.5,
    height: 200.25,
    content: content,
  );
}
