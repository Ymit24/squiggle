import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

void main() {
  Document docWithRectangle({
    Offset origin = Offset.zero,
    Size size = const Size(10, 10),
  }) => Document.fromFeatures([
    Feature(origin: origin, size: size, kind: const FeatureKindRectangle()),
  ]);

  group('AddFeatureCommand', () {
    test('apply assigns id and adds feature; undo removes it', () {
      final doc = Document();
      final feature = Feature(
        origin: const Offset(1, 2),
        size: const Size(3, 4),
        kind: const FeatureKindRectangle(),
      );
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

  group('UpdateFeaturesStyleCommand', () {
    test('apply updates style; undo restores previous kind', () {
      final doc = docWithRectangle();
      final id = doc.features.first.id;
      const newStroke = Color(0xFFF38BA8);
      final command = UpdateFeaturesStyleCommand(
        ids: [id],
        strokeColor: newStroke,
      );

      command.apply(doc);
      expect(doc.features.first.kind.strokeColor, newStroke);

      command.undo(doc);
      expect(doc.features.first.kind.strokeColor, const Color(0xFFFFFFFF));
    });

    test('apply updates multiple features in one step', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: Offset.zero,
          size: const Size(10, 10),
          kind: const FeatureKindRectangle(),
        ),
        Feature(
          origin: const Offset(20, 0),
          size: const Size(10, 10),
          kind: const FeatureKindCircle(),
        ),
      ]);
      final ids = doc.features.map((feature) => feature.id).toList();
      const newFill = Color(0xFF89B4FA);
      final command = UpdateFeaturesStyleCommand(
        ids: ids,
        fillColor: newFill,
      );

      command.apply(doc);
      expect(doc.features.every((feature) => feature.kind.fillColor == newFill), isTrue);

      command.undo(doc);
      expect(doc.features.every((feature) => feature.kind.fillColor == const Color(0xFF000000)), isTrue);
    });

    test('preserves text contents when updating style', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: Offset.zero,
          size: const Size(100, 24),
          kind: const FeatureKindText('hello', fillColor: Color(0xFFFFFFFF)),
        ),
      ]);
      final id = doc.features.first.id;
      final command = UpdateFeaturesStyleCommand(
        ids: [id],
        strokeWidth: 4,
      );

      command.apply(doc);
      final kind = doc.features.first.kind;
      expect(kind, isA<FeatureKindText>());
      expect((kind as FeatureKindText).contents, 'hello');
      expect(kind.strokeWidth, 4);
    });

    test('apply updates font size on text features only in mixed selection', () {
      final doc = Document.fromFeatures([
        Feature(
          origin: Offset.zero,
          size: const Size(10, 10),
          kind: const FeatureKindRectangle(),
        ),
        Feature(
          origin: const Offset(20, 0),
          size: const Size(100, 24),
          kind: const FeatureKindText('hello', fillColor: Color(0xFFFFFFFF)),
        ),
      ]);
      final ids = doc.features.map((feature) => feature.id).toList();
      final command = UpdateFeaturesStyleCommand(
        ids: ids,
        fontSize: FontSizePreset.small.size,
      );

      command.apply(doc);

      expect(doc.features.first.kind, isA<FeatureKindRectangle>());
      final textKind = doc.features.last.kind as FeatureKindText;
      expect(textKind.fontSize, FontSizePreset.small.size);
      expect(textKind.contents, 'hello');
    });
  });
}
