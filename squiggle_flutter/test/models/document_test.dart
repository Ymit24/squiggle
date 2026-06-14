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

  group('Document undo/redo', () {
    test('redo reapplies undone command', () {
      final doc = Document.fromFeatures([
        Feature.newRectangle(const Offset(0, 0), const Size(10, 10)),
      ]);
      final id = doc.features.first.id;

      doc.executeCommand(MoveFeatureCommand(id, const Offset(5, 5)));
      doc.undo();
      doc.redo();

      expect(doc.features.first.origin, const Offset(5, 5));
    });

    test('new command clears redo stack', () {
      final doc = Document.fromFeatures([
        Feature.newRectangle(const Offset(0, 0), const Size(10, 10)),
      ]);
      final id = doc.features.first.id;

      doc.executeCommand(MoveFeatureCommand(id, const Offset(5, 5)));
      doc.undo();
      doc.executeCommand(MoveFeatureCommand(id, const Offset(10, 10)));

      doc.redo();
      expect(doc.features.first.origin, const Offset(10, 10));
    });
  });
}
