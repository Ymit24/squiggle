import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';
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

    test('lock allows repeated shapes and follows manual tool changes', () {
      expect(context.tool.isLocked, isFalse);
      context.tool.toggleLock();
      context.setTool(CreateFeatureTool.rect());
      final rectangleTool = context.tool.activeTool;

      void draw(Offset start) {
        final end = start + const Offset(100, 50);
        pointerDown(start);
        pointerMove(start);
        pointerMove(end);
        pointerUp(end);
      }

      draw(Offset.zero);
      draw(const Offset(200, 200));
      expect(context.tool.activeTool, same(rectangleTool));
      expect(context.document.nodes, hasLength(2));
      expect(
        context.document.nodes.last.localBounds(),
        const Rect.fromLTWH(200, 200, 100, 50),
      );

      context.setTool(SelectTool());
      expect(context.tool.activeTool, isA<SelectTool>());
      expect(context.tool.isLocked, isTrue);
      context.setTool(CreateFeatureTool.circle());
      final circleTool = context.tool.activeTool;
      draw(const Offset(400, 400));
      expect(context.tool.activeTool, same(circleTool));
      expect(
        (context.document.nodes.last as Feature).kind,
        isA<FeatureKindCircle>(),
      );

      context.tool.toggleLock();
      expect(context.tool.activeTool, same(circleTool));
      draw(const Offset(600, 600));
      expect(context.document.nodes, hasLength(4));
      expect(context.tool.activeTool, isA<SelectTool>());
    });

    test('click without drag does not create feature', () {
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(context.document.nodes, isEmpty);
      expect(context.tool.activeTool, isA<CreateFeatureTool>());
    });

    test('drag creates rectangle feature', () {
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      final features = context.document.nodes.cast<Feature>();
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindRectangle>());
      expect(context.tool.activeTool, isA<SelectTool>());
      expect(features.first.localBounds(), const Rect.fromLTWH(0, 0, 100, 100));
    });

    test('drag creates circle feature', () {
      context.setTool(CreateFeatureTool.circle());

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      final features = context.document.nodes.cast<Feature>();
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindCircle>());
      expect(context.tool.activeTool, isA<SelectTool>());
      expect(features.first.localBounds(), const Rect.fromLTWH(0, 0, 100, 100));
    });

    test('shift-drag creates square rectangle from non-square drag', () {
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(100, 50), shift: true);
      pointerUp(const Offset(100, 50), shift: true);

      final features = context.document.nodes.cast<Feature>();
      expect(features, hasLength(1));
      expect(
        features.first.localBounds().width,
        features.first.localBounds().height,
      );
      expect(features.first.localBounds(), const Rect.fromLTWH(0, 0, 100, 100));
    });

    test('shift-drag creates square circle bounds from non-square drag', () {
      context.setTool(CreateFeatureTool.circle());

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(80, 140), shift: true);
      pointerUp(const Offset(80, 140), shift: true);

      final features = context.document.nodes.cast<Feature>();
      expect(
        features.first.localBounds().width,
        features.first.localBounds().height,
      );
      expect(features.first.localBounds().width, closeTo(140, 0.001));
    });

    test('alt-drag creates rectangle from center', () {
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(50, 50));
      pointerMove(const Offset(50, 50));
      pointerMove(const Offset(100, 80), alt: true);
      pointerUp(const Offset(100, 80), alt: true);

      expect(
        context.document.nodes.first.localBounds(),
        const Rect.fromLTWH(0, 20, 100, 60),
      );
    });

    test('alt-shift-drag creates square from center', () {
      context.setTool(CreateFeatureTool.circle());

      pointerDown(const Offset(50, 50));
      pointerMove(const Offset(50, 50));
      pointerMove(const Offset(100, 80), shift: true, alt: true);
      pointerUp(const Offset(100, 80), shift: true, alt: true);

      final bounds = context.document.nodes.first.localBounds();
      expect(bounds.width, bounds.height);
      expect(bounds, const Rect.fromLTWH(0, 0, 100, 100));
    });
  });
}
