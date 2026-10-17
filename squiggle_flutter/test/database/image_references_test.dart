import 'dart:ui';

import 'package:data_models/data_models.dart' as data;
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/image_references.dart';
import 'package:squiggle_flutter/models/feature.dart';

data.Feature _feature(int id, Map<String, dynamic> content) => data.Feature(
  id: id,
  originX: 0,
  originY: 0,
  width: 10,
  height: 10,
  content: content,
);

void main() {
  group('imageHashesIn', () {
    test('finds images at the root and inside nested groups', () {
      final nodes = [
        _feature(1, {'type': 'image', 'imageId': 'a'}),
        data.Group(
          id: 2,
          originX: 0,
          originY: 0,
          children: [
            _feature(3, {'type': 'image', 'imageId': 'b'}),
            data.Group(
              id: 4,
              originX: 0,
              originY: 0,
              children: [
                _feature(5, {'type': 'image', 'imageId': 'a'}),
              ],
            ),
          ],
        ),
      ];

      expect(imageHashesIn(nodes), {'a', 'b'});
    });

    test('ignores features that are not images', () {
      expect(
        imageHashesIn([
          _feature(1, {'type': 'rectangle'}),
        ]),
        isEmpty,
      );
    });

    test('understands what FeatureKindImage writes', () {
      final feature = Feature(
        origin: Offset.zero,
        size: const Size(10, 10),
        kind: FeatureKindImage('abc123'),
      );

      expect(imageHashesIn([feature.toDataModel()]), {'abc123'});
    });
  });
}
