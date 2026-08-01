import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';

void main() {
  group('CreateFeatureTool via EditorContext', () {
    late EditorContext context;
    late Camera camera;

    setUp(() {
      context = EditorContext(document: Document());
      camera = Camera();
    });

    void pointerDown(Offset world) {
      context.tool.onPointerDown(
        context,
        world,
        camera,
        isShiftPressed: false,
        isAltPressed: false,
      );
    }

    void pointerMove(Offset world, {bool shift = false, bool alt = false}) {
      context.tool.onPointerMove(
        context,
        world,
        camera,
        isShiftPressed: shift,
        isAltPressed: alt,
      );
    }

    void pointerUp(Offset world, {bool shift = false, bool alt = false}) {
      context.tool.onPointerUp(
        context,
        world,
        camera,
        isShiftPressed: shift,
        isAltPressed: alt,
      );
    }

    test('click without drag does not create feature', () {
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(context.document.features, isEmpty);
    });

    test('drag creates rectangle feature', () {
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      final features = context.document.features;
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindRectangle>());
      expect(features.first.bounds(), const Rect.fromLTWH(0, 0, 100, 100));
    });

    test('drag creates circle feature', () {
      context.setTool(CreateFeatureTool.circle());

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      final features = context.document.features;
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindCircle>());
      expect(features.first.bounds(), const Rect.fromLTWH(0, 0, 100, 100));
    });

    test('shift-drag creates square rectangle from non-square drag', () {
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(100, 50), shift: true);
      pointerUp(const Offset(100, 50), shift: true);

      final features = context.document.features;
      expect(features, hasLength(1));
      expect(features.first.bounds().width, features.first.bounds().height);
      expect(features.first.bounds(), const Rect.fromLTWH(0, 0, 100, 100));
    });

    test('shift-drag creates square circle bounds from non-square drag', () {
      context.setTool(CreateFeatureTool.circle());

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(80, 140), shift: true);
      pointerUp(const Offset(80, 140), shift: true);

      final features = context.document.features;
      expect(features.first.bounds().width, features.first.bounds().height);
      expect(features.first.bounds().width, closeTo(140, 0.001));
    });

    test('alt-drag creates rectangle from center', () {
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(50, 50));
      pointerMove(const Offset(50, 50));
      pointerMove(const Offset(100, 80), alt: true);
      pointerUp(const Offset(100, 80), alt: true);

      expect(
        context.document.features.first.bounds(),
        const Rect.fromLTWH(0, 20, 100, 60),
      );
    });

    test('alt-shift-drag creates square from center', () {
      context.setTool(CreateFeatureTool.circle());

      pointerDown(const Offset(50, 50));
      pointerMove(const Offset(50, 50));
      pointerMove(const Offset(100, 80), shift: true, alt: true);
      pointerUp(const Offset(100, 80), shift: true, alt: true);

      final bounds = context.document.features.first.bounds();
      expect(bounds.width, bounds.height);
      expect(bounds, const Rect.fromLTWH(0, 0, 100, 100));
    });
  });
}
