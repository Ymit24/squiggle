import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
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

    void paintPreview() {
      final recorder = PictureRecorder();
      context.tool.activeTool.paint(
        Canvas(recorder),
        camera,
        context,
        ImageRepository(),
      );
      recorder.endRecording().dispose();
    }

    test('click without drag does not create feature', () {
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(context.document.nodes, isEmpty);
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

    test('repaints and commits one styled feature for a drag', () {
      final countingContext = _CountingEditorContext(document: Document());
      context = countingContext;
      context.rememberInspectorValue('strokeColor', const Color(0xFFFF0000));
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(10, 20));
      pointerMove(const Offset(10, 20));
      paintPreview();
      paintPreview();
      pointerMove(const Offset(90, 70));
      paintPreview();
      context.rememberInspectorValue('strokeColor', const Color(0xFF0000FF));
      paintPreview();

      expect(countingContext.styleApplications, 1);
      pointerUp(const Offset(90, 70));
      final feature = context.document.nodes.single as Feature;
      expect(feature.localBounds(), const Rect.fromLTWH(10, 20, 80, 50));
      expect(
        (feature.kind as FeatureKindRectangle).strokeColor,
        const Color(0xFFFF0000),
      );
      expect(countingContext.styleApplications, 1);

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      pointerMove(const Offset(20, 20));
      pointerUp(const Offset(20, 20));
      expect(countingContext.styleApplications, 2);
      expect(
        ((context.document.nodes.last as Feature).kind as FeatureKindRectangle)
            .strokeColor,
        const Color(0xFF0000FF),
      );
    });

    test('cancellation and deactivation discard the preview', () {
      final countingContext = _CountingEditorContext(document: Document());
      context = countingContext;
      context.setTool(CreateFeatureTool.rect());

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(0, 0));
      context.cancelInteraction();
      paintPreview();
      expect(context.document.nodes, isEmpty);

      pointerDown(const Offset(10, 10));
      pointerMove(const Offset(10, 10));
      expect(countingContext.styleApplications, 2);
      context.setTool(CreateFeatureTool.circle());
      paintPreview();
      expect(context.document.nodes, isEmpty);

      context.setTool(CreateFeatureTool.rect());
      pointerDown(const Offset(20, 20));
      pointerMove(const Offset(20, 20));
      expect(countingContext.styleApplications, 3);
    });
  });
}

class _CountingEditorContext extends EditorContext {
  _CountingEditorContext({required super.document});

  int styleApplications = 0;

  @override
  void applyInspectorValues(FeatureKind kind) {
    styleApplications++;
    super.applyInspectorValues(kind);
  }
}
