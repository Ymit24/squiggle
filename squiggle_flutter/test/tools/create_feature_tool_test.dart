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

    tearDown(() => context.dispose());

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

    for (final tool in [CreateFeatureTool.rect(), CreateFeatureTool.circle()]) {
      test('${tool.kind.runtimeType} follows brush changes during drag', () {
        context.brushes.setField('strokeWidth', 8);
        final scratchId = context.brushes.active.id;
        final sparseBrush = context.brushes.create('Sparse');
        context.brushes.clearField('strokeWidth');
        context.brushes.activate(scratchId);
        context.setTool(tool);

        pointerDown(const Offset(10, 20));
        pointerMove(const Offset(10, 20));
        pointerMove(const Offset(110, 70));
        context.brushes.activate(sparseBrush.id);
        context.brushes.setField('fillColor', 0xFF123456);
        context.brushes.setField('strokeType', 'dashed');
        context.brushes.clearField('strokeType');
        expect(context.document.nodes, isEmpty);
        expect(context.history.canUndo, isFalse);

        // No further move: commit the already-restyled preview.
        pointerUp(const Offset(110, 70));
        final feature = context.document.nodes.single as Feature;
        final styles = feature.kind.toDataModel();
        expect(styles['strokeWidth'], tool.kind.toDataModel()['strokeWidth']);
        expect(styles['strokeType'], 'solid');
        expect(styles['fillColor'], 0xFF123456);
        expect(feature.localBounds(), const Rect.fromLTWH(10, 20, 100, 50));

        context.undo();
        expect(context.document.nodes, isEmpty);
        expect(context.history.canUndo, isFalse);
        expect(context.brushes.active.id, sparseBrush.id);
        context.redo();
        expect(
          (context.document.nodes.single as Feature).kind.toDataModel(),
          styles,
        );
      });
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
      expect(context.selection.isEmpty, isTrue);
      final previousId = context.document.nodes.first.id;
      context.selection.setSelection([previousId]);
      draw(const Offset(200, 200));
      expect(context.tool.activeTool, same(rectangleTool));
      expect(context.document.nodes, hasLength(2));
      expect(context.selection.selectedNodeIds, [previousId]);
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
      expect(context.selection.selectedNodeIds, [
        context.document.nodes.last.id,
      ]);
    });

    test('click without drag does not create feature', () {
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(context.document.nodes, isEmpty);
      expect(context.tool.activeTool, isA<CreateFeatureTool>());
    });

    test('drag creates rectangle feature', () {
      final previous = Feature(
        origin: const Offset(200, 200),
        size: const Size(50, 50),
        kind: FeatureKindRectangle(),
      );
      context.document.addNode(previous);
      context.selection.setSelection([previous.id]);
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      final features = context.document.nodes.skip(1).cast<Feature>();
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindRectangle>());
      expect(context.selection.selectedNodeIds, [features.first.id]);
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
      expect(context.selection.selectedNodeIds, [features.first.id]);
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
