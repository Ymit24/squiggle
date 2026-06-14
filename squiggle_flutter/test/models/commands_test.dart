import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

void main() {
  Document docWithRectangle({
    Offset origin = Offset.zero,
    Size size = const Size(10, 10),
  }) => Document.fromFeatures([Feature.newRectangle(origin, size)]);

  group('AddFeatureCommand', () {
    test('apply assigns id and adds feature; undo removes it', () {
      final doc = Document();
      final feature = Feature.newRectangle(const Offset(1, 2), const Size(3, 4));
      final command = AddFeatureCommand(feature);

      command.apply(doc);
      expect(feature.id, isNot(noId));
      expect(doc.features, [feature]);

      command.undo(doc);
      expect(doc.features, isEmpty);
    });
  });

  group('MoveFeatureCommand', () {
    test('apply moves feature; undo restores origin', () {
      final doc = docWithRectangle();
      final id = doc.features.first.id;
      final command = MoveFeatureCommand(id, const Offset(5, 5));

      command.apply(doc);
      expect(doc.features.first.origin, const Offset(5, 5));

      command.undo(doc);
      expect(doc.features.first.origin, Offset.zero);
    });
  });

  group('RemoveFeaturesCommand', () {
    test('apply removes features; undo restores them', () {
      final doc = docWithRectangle(origin: const Offset(2, 3));
      final id = doc.features.first.id;
      final command = RemoveFeaturesCommand([id]);

      command.apply(doc);
      expect(doc.features, isEmpty);

      command.undo(doc);
      expect(doc.features, hasLength(1));
      expect(doc.features.first.origin, const Offset(2, 3));
    });
  });

  group('ResizeFeatureCommand', () {
    test('apply resizes feature; undo restores bounds', () {
      final doc = docWithRectangle();
      final id = doc.features.first.id;
      const newBounds = Rect.fromLTWH(1, 2, 20, 30);
      final command = ResizeFeatureCommand(id, newBounds);

      command.apply(doc);
      expect(doc.features.first.bounds(), newBounds);

      command.undo(doc);
      expect(doc.features.first.bounds(), const Rect.fromLTWH(0, 0, 10, 10));
    });
  });
}
