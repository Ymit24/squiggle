import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/tools/select_tool.dart'
    show
        SelectTool,
        kSelectionBoxPadding,
        kSelectionHandleHitSize,
        selectionBoxWorldBounds;

enum _SelectionEdge { top, right, bottom, left }

void main() {
  group('SelectTool via ToolRepository', () {
    late DocumentRepository documentRepository;
    late SelectionRepository selectionRepository;
    late ToolRepository toolRepository;
    late TextEditRepository textEditRepository;
    late Camera camera;

    setUp(() {
      camera = Camera();
      textEditRepository = TextEditRepository();
      documentRepository = DocumentRepository(
        document: Document.fromFeatures([
          Feature(origin: const Offset(0, 0), size: const Size(100, 100), kind: const FeatureKindRectangle()),
          Feature(origin: const Offset(200, 0), size: const Size(100, 100), kind: const FeatureKindRectangle()),
        ]),
      );
      selectionRepository = SelectionRepository();
      toolRepository = ToolRepository();
    });

    tearDown(() {
      toolRepository.dispose();
      textEditRepository.dispose();
      documentRepository.dispose();
    });

    void pointerDown(Offset world, {bool shift = false}) {
      toolRepository.onPointerDown(
        documentRepository,
        world,
        selectionRepository,
        shift,
        camera,
      );
    }

    void pointerUp(Offset world, {bool shift = false}) {
      toolRepository.onPointerUp(
        documentRepository,
        world,
        selectionRepository,
        shift,
        camera,
        textEditRepository,
      );
    }

    void pointerMove(Offset world, {bool shift = false}) {
      toolRepository.onPointerMove(
        documentRepository,
        world,
        selectionRepository,
        shift,
        camera,
      );
    }

    void doubleClick(Offset world, {bool shift = false}) {
      pointerDown(world, shift: shift);
      pointerUp(world, shift: shift);
      pointerDown(world, shift: shift);
      pointerUp(world, shift: shift);
    }

    bool keyDown(LogicalKeyboardKey key) {
      return toolRepository.onKeyEvent(
        documentRepository,
        KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: key,
          timeStamp: Duration.zero,
        ),
      );
    }

    List<Offset> polylineWorldPoints(Feature feature) {
      final kind = feature.kind as FeatureKindPolyline;
      return worldPoints(feature.origin, kind.localPoints);
    }

    DocumentRepository polylineDocument() {
      return DocumentRepository(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(100, 100),
            kind: const FeatureKindPolyline(
              [Offset.zero, Offset(100, 100)],
              strokeColor: Color(0xFFFFFFFF),
              fillColor: Color(0xFF89B4FA),
            ),
          ),
        ]),
      );
    }

    Offset edgeHitWorldPoint(Rect featureBounds, _SelectionEdge edge) {
      final screenBounds = camera.worldToScreenBounds(featureBounds).inflate(
        kSelectionBoxPadding,
      );
      final half = kSelectionHandleHitSize / 2;
      final screenPoint = switch (edge) {
        _SelectionEdge.top => Offset(
          (screenBounds.left + screenBounds.right) / 2,
          screenBounds.top - half,
        ),
        _SelectionEdge.bottom => Offset(
          (screenBounds.left + screenBounds.right) / 2,
          screenBounds.bottom - half,
        ),
        _SelectionEdge.left => Offset(
          screenBounds.left - half,
          (screenBounds.top + screenBounds.bottom) / 2,
        ),
        _SelectionEdge.right => Offset(
          screenBounds.right - half,
          (screenBounds.top + screenBounds.bottom) / 2,
        ),
      };
      return camera.screenToWorld(screenPoint);
    }

    test('selects feature on click', () {
      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));

      expect(selectionRepository.selectedFeatures.length, 1);
      expect(
        selectionRepository.selectedFeatures.single,
        documentRepository.document.features.first.id,
      );
    });

    test('switches selection when clicking another feature', () {
      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      pointerDown(const Offset(250, 50));
      pointerUp(const Offset(250, 50));

      expect(selectionRepository.selectedFeatures.length, 1);
      expect(
        selectionRepository.selectedFeatures.single,
        documentRepository.document.features[1].id,
      );
    });

    test('clears selection on empty click', () {
      selectionRepository.selectFeature(
        documentRepository.document.features.first.id,
      );
      pointerDown(const Offset(500, 500));
      pointerUp(const Offset(500, 500));

      expect(selectionRepository.selectedFeatures, isEmpty);
    });

    test('shift-click adds and removes from selection', () {
      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      pointerDown(const Offset(250, 50), shift: true);
      pointerUp(const Offset(250, 50), shift: true);
      pointerDown(const Offset(50, 50), shift: true);
      pointerUp(const Offset(50, 50), shift: true);

      expect(selectionRepository.selectedFeatures.length, 1);
      expect(
        selectionRepository.selectedFeatures.single,
        documentRepository.document.features[1].id,
      );
    });

    test('shift-click on empty preserves selection', () {
      selectionRepository.selectFeature(
        documentRepository.document.features.first.id,
      );
      pointerDown(const Offset(500, 500), shift: true);
      pointerUp(const Offset(500, 500), shift: true);

      expect(selectionRepository.selectedFeatures.length, 1);
      expect(
        selectionRepository.selectedFeatures.single,
        documentRepository.document.features.first.id,
      );
    });

    test('notifies repaint while marquee selecting', () async {
      final repaints = <void>[];
      final subscription = toolRepository.repaintStream.listen(repaints.add);

      pointerDown(const Offset(500, 500));
      pointerMove(const Offset(600, 600));
      await Future<void>.delayed(Duration.zero);

      expect(repaints, isNotEmpty);
      expect(toolRepository.activeTool, isA<SelectTool>());
      await subscription.cancel();
    });

    test('moves group relative to clicked feature, not last selected', () {
      documentRepository = DocumentRepository(
        document: Document.fromFeatures([
          Feature(origin: const Offset(0, 0), size: const Size(50, 50), kind: const FeatureKindRectangle()),
          Feature(origin: const Offset(100, 0), size: const Size(50, 50), kind: const FeatureKindRectangle()),
          Feature(origin: const Offset(200, 0), size: const Size(50, 50), kind: const FeatureKindRectangle()),
        ]),
      );
      final features = documentRepository.document.features;
      final idA = features[0].id;
      final idB = features[1].id;
      final idC = features[2].id;

      pointerDown(const Offset(25, 25));
      pointerUp(const Offset(25, 25));
      pointerDown(const Offset(125, 25), shift: true);
      pointerUp(const Offset(125, 25), shift: true);
      pointerDown(const Offset(225, 25), shift: true);
      pointerUp(const Offset(225, 25), shift: true);
      expect(selectionRepository.selectedFeatures, [idA, idB, idC]);

      pointerDown(const Offset(25, 25));
      pointerMove(const Offset(35, 35));

      expect(documentRepository.document.featureById(idA)!.origin, const Offset(10, 10));
      expect(documentRepository.document.featureById(idB)!.origin, const Offset(110, 10));
      expect(documentRepository.document.featureById(idC)!.origin, const Offset(210, 10));
    });

    test('emits document changes on move', () async {
      pointerDown(const Offset(50, 50));
      final changes = <void>[];
      final subscription = documentRepository.changesStream.listen(changes.add);
      pointerMove(const Offset(60, 60));
      await Future<void>.delayed(Duration.zero);
      expect(changes, isNotEmpty);
      await subscription.cancel();
    });

    test('resize does not snap on first move when grab is off-center on handle', () {
      final feature = documentRepository.document.features.first;
      selectionRepository.selectFeature(feature.id);

      final bounds = feature.bounds();
      final inflated = selectionBoxWorldBounds(bounds);
      final handleWorld = camera.screenLengthToWorldLength(
        kSelectionHandleHitSize / 2,
      );
      final down = inflated.bottomRight + Offset(handleWorld, handleWorld);

      pointerDown(down);
      pointerMove(down);

      final unchanged = documentRepository.document.featureById(feature.id)!;
      expect(unchanged.bounds(), bounds);
    });

    test('resizes single selection from bottom-right handle', () {
      final feature = documentRepository.document.features.first;
      selectionRepository.selectFeature(feature.id);

      final bounds = feature.bounds();
      final inflated = selectionBoxWorldBounds(bounds);
      final handleWorld = camera.screenLengthToWorldLength(
        kSelectionHandleHitSize / 2,
      );
      final down = inflated.bottomRight + Offset(handleWorld, handleWorld);
      final grabOffset = down - bounds.bottomRight;
      const targetCorner = Offset(150, 150);

      pointerDown(down);
      pointerMove(targetCorner + grabOffset);
      pointerUp(targetCorner + grabOffset);

      final resized = documentRepository.document.featureById(feature.id)!;
      expect(resized.origin, bounds.topLeft);
      expect(resized.size.width, 150);
      expect(resized.size.height, 150);
    });

    test('resizes single selection from top edge', () {
      final feature = documentRepository.document.features.first;
      selectionRepository.selectFeature(feature.id);

      final bounds = feature.bounds();
      final down = edgeHitWorldPoint(bounds, _SelectionEdge.top);
      final grabOffset = down - bounds.topLeft;
      const targetTop = Offset(50, -50);

      pointerDown(down);
      pointerMove(targetTop + grabOffset);
      pointerUp(targetTop + grabOffset);

      final resized = documentRepository.document.featureById(feature.id)!;
      expect(resized.origin, const Offset(0, -50));
      expect(resized.size.width, 100);
      expect(resized.size.height, 150);
    });

    test('resizes single selection from right edge', () {
      final feature = documentRepository.document.features.first;
      selectionRepository.selectFeature(feature.id);

      final bounds = feature.bounds();
      final down = edgeHitWorldPoint(bounds, _SelectionEdge.right);
      final grabOffset = down - bounds.bottomRight;
      const targetRight = Offset(200, 50);

      pointerDown(down);
      pointerMove(targetRight + grabOffset);
      pointerUp(targetRight + grabOffset);

      final resized = documentRepository.document.featureById(feature.id)!;
      expect(resized.origin, bounds.topLeft);
      expect(resized.size.width, 200);
      expect(resized.size.height, 100);
    });

    test('edge resize does not snap on first move when grab is off-center', () {
      final feature = documentRepository.document.features.first;
      selectionRepository.selectFeature(feature.id);

      final bounds = feature.bounds();
      final down = edgeHitWorldPoint(bounds, _SelectionEdge.top) +
          const Offset(10, 0);

      pointerDown(down);
      pointerMove(down);

      final unchanged = documentRepository.document.featureById(feature.id)!;
      expect(unchanged.bounds(), bounds);
    });

    test('does not resize when multiple features are selected', () {
      final features = documentRepository.document.features;
      selectionRepository.selectFeature(features[0].id);
      selectionRepository.selectFeature(features[1].id);

      final bounds = features[0].bounds();
      final inflated = selectionBoxWorldBounds(bounds);
      final handleWorld = camera.screenLengthToWorldLength(
        kSelectionHandleHitSize / 2,
      );
      final down = inflated.bottomRight + Offset(handleWorld, handleWorld);

      pointerDown(down);
      pointerMove(const Offset(150, 150));
      pointerUp(const Offset(150, 150));

      expect(features[0].bounds(), bounds);
    });

    test('selects and resizes polyline by segment click and corner handle', () {
      documentRepository = DocumentRepository(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(100, 100),
            kind: const FeatureKindPolyline(
              [Offset.zero, Offset(100, 100)],
              strokeColor: Color(0xFFFFFFFF),
              fillColor: Color(0xFF89B4FA),
            ),
          ),
        ]),
      );
      final feature = documentRepository.document.features.first;
      final endBefore = feature.origin + (feature.kind as FeatureKindPolyline).localPoints.last;

      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      expect(selectionRepository.selectedFeatures.single, feature.id);

      final bounds = feature.bounds();
      final inflated = selectionBoxWorldBounds(bounds);
      final handleWorld = camera.screenLengthToWorldLength(
        kSelectionHandleHitSize / 2,
      );
      final down = inflated.bottomRight + Offset(handleWorld, handleWorld);
      final grabOffset = down - bounds.bottomRight;
      const targetCorner = Offset(142, 142);

      pointerDown(down);
      pointerMove(targetCorner + grabOffset);
      pointerUp(targetCorner + grabOffset);

      final resized = documentRepository.document.featureById(feature.id)!;
      final endAfter = resized.origin + (resized.kind as FeatureKindPolyline).localPoints.last;
      expect(resized.size.width, 150);
      expect(resized.size.height, 150);
      expect(endAfter, isNot(endBefore));
    });

    test('double-click polyline enters edit mode and drags vertex', () {
      documentRepository = polylineDocument();
      final feature = documentRepository.document.features.first;

      doubleClick(const Offset(50, 50));
      expect(selectionRepository.selectedFeatures.single, feature.id);

      final endBefore = polylineWorldPoints(feature).last;
      pointerDown(const Offset(100, 100));
      pointerMove(const Offset(150, 100));
      pointerUp(const Offset(150, 100));

      final moved = documentRepository.document.featureById(feature.id)!;
      expect(polylineWorldPoints(moved).last, const Offset(150, 100));
      expect(polylineWorldPoints(moved).last, isNot(endBefore));
    });

    test('escape exits edit mode and preserves selection', () {
      documentRepository = polylineDocument();
      final feature = documentRepository.document.features.first;

      doubleClick(const Offset(50, 50));
      expect(keyDown(LogicalKeyboardKey.escape), isTrue);
      expect(selectionRepository.selectedFeatures.single, feature.id);
    });

    test('empty click exits edit mode and clears selection', () {
      documentRepository = polylineDocument();
      final feature = documentRepository.document.features.first;

      doubleClick(const Offset(50, 50));
      pointerDown(const Offset(500, 500));
      pointerUp(const Offset(500, 500));

      expect(selectionRepository.selectedFeatures, isEmpty);
    });

    test('undo restores vertex geometry after edit drag', () {
      documentRepository = polylineDocument();
      final feature = documentRepository.document.features.first;

      doubleClick(const Offset(50, 50));
      pointerDown(const Offset(100, 100));
      pointerMove(const Offset(150, 100));
      pointerUp(const Offset(150, 100));

      final afterDrag = polylineWorldPoints(
        documentRepository.document.featureById(feature.id)!,
      );
      expect(afterDrag.last, const Offset(150, 100));

      documentRepository.document.undo();
      final restored = documentRepository.document.featureById(feature.id)!;
      expect(polylineWorldPoints(restored).last, const Offset(100, 100));
    });

    test('double-click non-polyline enters edit mode without vertex side effects', () {
      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));

      final feature = documentRepository.document.features.first;
      expect(selectionRepository.selectedFeatures.single, feature.id);
      expect(keyDown(LogicalKeyboardKey.escape), isTrue);
      expect(selectionRepository.selectedFeatures.single, feature.id);
    });

    test('corner resize scales text font size to fill new bounds', () {
      const contents = 'Line one\nLine two\nLine three';
      documentRepository = DocumentRepository(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(200, 80),
            kind: const FeatureKindText(
              contents,
              fillColor: Color(0xFFFFFFFF),
            ),
          ),
        ]),
      );
      final feature = documentRepository.document.features.first;
      selectionRepository.selectFeature(feature.id);
      final initialFontSize =
          (feature.kind as FeatureKindText).fontSize;

      final bounds = feature.bounds();
      final inflated = selectionBoxWorldBounds(bounds);
      final handleWorld = camera.screenLengthToWorldLength(
        kSelectionHandleHitSize / 2,
      );
      final down = inflated.bottomRight + Offset(handleWorld, handleWorld);
      final grabOffset = down - bounds.bottomRight;
      const targetCorner = Offset(300, 300);

      pointerDown(down);
      pointerMove(targetCorner + grabOffset);
      pointerUp(targetCorner + grabOffset);

      final resized = documentRepository.document.featureById(feature.id)!;
      final textKind = resized.kind as FeatureKindText;
      expect(resized.origin, bounds.topLeft);
      expect(resized.size.width, 300);
      expect(resized.size.height, 300);
      expect(textKind.fontSize, greaterThan(initialFontSize));
      expect(
        textKind.measureContents(
          width: 300,
          fontSize: textKind.fontSize,
        ).height,
        lessThanOrEqualTo(300),
      );
    });

    test('vertical resize scales text font size to fill taller box', () {
      documentRepository = DocumentRepository(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(200, 48),
            kind: const FeatureKindText(
              'hello world',
              fillColor: Color(0xFFFFFFFF),
            ),
          ),
        ]),
      );
      final feature = documentRepository.document.features.first;
      selectionRepository.selectFeature(feature.id);
      final initialFontSize =
          (feature.kind as FeatureKindText).fontSize;

      final bounds = feature.bounds();
      final down = edgeHitWorldPoint(bounds, _SelectionEdge.bottom);
      final grabOffset = down - bounds.bottomRight;
      const targetBottom = Offset(200, 200);

      pointerDown(down);
      pointerMove(targetBottom + grabOffset);
      pointerUp(targetBottom + grabOffset);

      final resized = documentRepository.document.featureById(feature.id)!;
      final textKind = resized.kind as FeatureKindText;
      expect(resized.size.width, 200);
      expect(resized.size.height, 200);
      expect(textKind.fontSize, greaterThan(initialFontSize));
    });

    test('double-click text opens edit session without entering edit mode', () async {
      textEditRepository = TextEditRepository();
      documentRepository = DocumentRepository(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(200, 48),
            kind: const FeatureKindText(
              'hello world',
              fillColor: Color(0xFFFFFFFF),
            ),
          ),
        ]),
      );
      final feature = documentRepository.document.features.first;
      final sessions = <TextEditSession>[];
      final subscription = textEditRepository.editSessionStream.listen(
        sessions.add,
      );

      doubleClick(const Offset(50, 24));
      await Future<void>.delayed(Duration.zero);

      expect(selectionRepository.selectedFeatures.single, feature.id);
      expect(sessions, hasLength(1));
      expect(sessions.first, isA<EditTextEditSession>());
      expect((sessions.first as EditTextEditSession).featureId, feature.id);
      expect(sessions.first.initialContents, 'hello world');
      expect(
        sessions.first.canvasLocalBounds,
        camera.worldToScreenBounds(feature.bounds()),
      );
      expect(keyDown(LogicalKeyboardKey.escape), isFalse);

      await subscription.cancel();
    });

    test('double-click polyline does not open text edit session', () async {
      textEditRepository = TextEditRepository();
      documentRepository = polylineDocument();
      final sessions = <TextEditSession>[];
      final subscription = textEditRepository.editSessionStream.listen(
        sessions.add,
      );

      doubleClick(const Offset(50, 50));

      expect(sessions, isEmpty);

      await subscription.cancel();
    });
  });
}
