import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart'
    show
        SelectTool,
        kSelectionBoxPadding,
        kSelectionHandleHitSize,
        selectionBoxWorldBounds;

enum _SelectionEdge { top, right, bottom, left }

void main() {
  group('SelectTool via EditorContext', () {
    late EditorContext context;
    late Camera camera;

    setUp(() {
      camera = Camera();
      context = EditorContext(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(100, 100),
            kind: const FeatureKindRectangle(),
          ),
          Feature(
            origin: const Offset(200, 0),
            size: const Size(100, 100),
            kind: const FeatureKindRectangle(),
          ),
        ]),
      );
    });

    void pointerDown(Offset world, {bool shift = false, bool alt = false}) {
      context.tool.onPointerDown(
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

    void pointerMove(Offset world, {bool shift = false, bool alt = false}) {
      context.tool.onPointerMove(
        context,
        world,
        camera,
        isShiftPressed: shift,
        isAltPressed: alt,
      );
    }

    void doubleClick(Offset world, {bool shift = false}) {
      pointerDown(world, shift: shift);
      pointerUp(world, shift: shift);
      pointerDown(world, shift: shift);
      pointerUp(world, shift: shift);
    }

    bool keyDown(LogicalKeyboardKey key) {
      return context.tool.onKeyEvent(
        context,
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

    EditorContext polylineDocument() {
      return EditorContext(
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
      final screenBounds = camera
          .worldToScreenBounds(featureBounds)
          .inflate(kSelectionBoxPadding);
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

      expect(context.selection.selectedFeatures.length, 1);
      expect(
        context.selection.selectedFeatures.single,
        context.document.features.first.id,
      );
    });

    test('switches selection when clicking another feature', () {
      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      pointerDown(const Offset(250, 50));
      pointerUp(const Offset(250, 50));

      expect(context.selection.selectedFeatures.length, 1);
      expect(
        context.selection.selectedFeatures.single,
        context.document.features[1].id,
      );
    });

    test('clears selection on empty click', () {
      context.selection.selectFeature(context.document.features.first.id);
      pointerDown(const Offset(500, 500));
      pointerUp(const Offset(500, 500));

      expect(context.selection.selectedFeatures, isEmpty);
    });

    test('shift-click adds and removes from selection', () {
      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      pointerDown(const Offset(250, 50), shift: true);
      pointerUp(const Offset(250, 50), shift: true);
      pointerDown(const Offset(50, 50), shift: true);
      pointerUp(const Offset(50, 50), shift: true);

      expect(context.selection.selectedFeatures.length, 1);
      expect(
        context.selection.selectedFeatures.single,
        context.document.features[1].id,
      );
    });

    test('shift-click on empty preserves selection', () {
      context.selection.selectFeature(context.document.features.first.id);
      pointerDown(const Offset(500, 500), shift: true);
      pointerUp(const Offset(500, 500), shift: true);

      expect(context.selection.selectedFeatures.length, 1);
      expect(
        context.selection.selectedFeatures.single,
        context.document.features.first.id,
      );
    });

    test('notifies repaint while marquee selecting', () async {
      final repaints = <void>[];
      final subscription = notifierChangesStream(context.tool).listen((_) {
        repaints.add(null);
      });

      pointerDown(const Offset(500, 500));
      pointerMove(const Offset(600, 600));
      await Future<void>.delayed(Duration.zero);

      expect(repaints, isNotEmpty);
      expect(context.tool.activeTool, isA<SelectTool>());
      await subscription.cancel();
    });

    test('moves group relative to clicked feature, not last selected', () {
      context = EditorContext(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(50, 50),
            kind: const FeatureKindRectangle(),
          ),
          Feature(
            origin: const Offset(100, 0),
            size: const Size(50, 50),
            kind: const FeatureKindRectangle(),
          ),
          Feature(
            origin: const Offset(200, 0),
            size: const Size(50, 50),
            kind: const FeatureKindRectangle(),
          ),
        ]),
      );
      final features = context.document.features;
      final idA = features[0].id;
      final idB = features[1].id;
      final idC = features[2].id;

      pointerDown(const Offset(25, 25));
      pointerUp(const Offset(25, 25));
      pointerDown(const Offset(125, 25), shift: true);
      pointerUp(const Offset(125, 25), shift: true);
      pointerDown(const Offset(225, 25), shift: true);
      pointerUp(const Offset(225, 25), shift: true);
      expect(context.selection.selectedFeatures, [idA, idB, idC]);

      pointerDown(const Offset(25, 25));
      pointerMove(const Offset(35, 35));

      expect(context.document.featureById(idA)!.origin, const Offset(10, 10));
      expect(context.document.featureById(idB)!.origin, const Offset(110, 10));
      expect(context.document.featureById(idC)!.origin, const Offset(210, 10));
    });

    test('emits document changes on move', () async {
      pointerDown(const Offset(50, 50));
      final changes = <void>[];
      final subscription = notifierChangesStream(context).listen((_) {
        changes.add(null);
      });
      pointerMove(const Offset(60, 60));
      await Future<void>.delayed(Duration.zero);
      expect(changes, isNotEmpty);
      await subscription.cancel();
    });

    test('commits one undo state for a feature drag', () {
      final feature = context.document.features.first;

      pointerDown(const Offset(50, 50));
      pointerMove(const Offset(60, 60));
      pointerMove(const Offset(70, 70));
      pointerMove(const Offset(80, 80));

      expect(feature.origin, const Offset(30, 30));
      expect(context.history.undoCount, 0);

      pointerUp(const Offset(80, 80));

      expect(context.history.undoCount, 1);
      context.undo();
      expect(feature.origin, Offset.zero);
    });

    test('commits one undo state for a multi-feature drag', () {
      final features = context.document.features;
      context.selection.selectFeature(features[0].id);
      context.selection.selectFeature(features[1].id);

      pointerDown(const Offset(50, 50));
      pointerMove(const Offset(60, 60));
      pointerMove(const Offset(70, 70));
      pointerUp(const Offset(70, 70));

      expect(context.history.undoCount, 1);
      expect(features[0].origin, const Offset(20, 20));
      expect(features[1].origin, const Offset(220, 20));

      context.undo();
      expect(features[0].origin, Offset.zero);
      expect(features[1].origin, const Offset(200, 0));
    });

    test(
      'resize does not snap on first move when grab is off-center on handle',
      () {
        final feature = context.document.features.first;
        context.selection.selectFeature(feature.id);

        final bounds = feature.bounds();
        final inflated = selectionBoxWorldBounds(bounds);
        final handleWorld = camera.screenLengthToWorldLength(
          kSelectionHandleHitSize / 2,
        );
        final down = inflated.bottomRight + Offset(handleWorld, handleWorld);

        pointerDown(down);
        pointerMove(down);

        final unchanged = context.document.featureById(feature.id)!;
        expect(unchanged.bounds(), bounds);
      },
    );

    test('resizes single selection from bottom-right handle', () {
      final feature = context.document.features.first;
      context.selection.selectFeature(feature.id);

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

      final resized = context.document.featureById(feature.id)!;
      expect(resized.origin, bounds.topLeft);
      expect(resized.size.width, 150);
      expect(resized.size.height, 150);
    });

    test('commits one undo state for a resize drag', () {
      final feature = context.document.features.first;
      context.selection.selectFeature(feature.id);

      final bounds = feature.bounds();
      final inflated = selectionBoxWorldBounds(bounds);
      final handleWorld = camera.screenLengthToWorldLength(
        kSelectionHandleHitSize / 2,
      );
      final down = inflated.bottomRight + Offset(handleWorld, handleWorld);
      final grabOffset = down - bounds.bottomRight;

      pointerDown(down);
      pointerMove(const Offset(120, 120) + grabOffset);
      pointerMove(const Offset(140, 140) + grabOffset);
      pointerMove(const Offset(160, 160) + grabOffset);

      expect(feature.size, const Size(160, 160));
      expect(context.history.undoCount, 0);

      pointerUp(const Offset(160, 160) + grabOffset);

      expect(context.history.undoCount, 1);
      context.undo();
      expect(feature.bounds(), bounds);
    });

    test('resizes single selection from top edge', () {
      final feature = context.document.features.first;
      context.selection.selectFeature(feature.id);

      final bounds = feature.bounds();
      final down = edgeHitWorldPoint(bounds, _SelectionEdge.top);
      final grabOffset = down - bounds.topLeft;
      const targetTop = Offset(50, -50);

      pointerDown(down);
      pointerMove(targetTop + grabOffset);
      pointerUp(targetTop + grabOffset);

      final resized = context.document.featureById(feature.id)!;
      expect(resized.origin, const Offset(0, -50));
      expect(resized.size.width, 100);
      expect(resized.size.height, 150);
    });

    test('resizes single selection from right edge', () {
      final feature = context.document.features.first;
      context.selection.selectFeature(feature.id);

      final bounds = feature.bounds();
      final down = edgeHitWorldPoint(bounds, _SelectionEdge.right);
      final grabOffset = down - bounds.bottomRight;
      const targetRight = Offset(200, 50);

      pointerDown(down);
      pointerMove(targetRight + grabOffset);
      pointerUp(targetRight + grabOffset);

      final resized = context.document.featureById(feature.id)!;
      expect(resized.origin, bounds.topLeft);
      expect(resized.size.width, 200);
      expect(resized.size.height, 100);
    });

    test(
      'alt-resize from bottom-right handle resizes symmetrically from center',
      () {
        final feature = context.document.features.first;
        context.selection.selectFeature(feature.id);

        final bounds = feature.bounds();
        final center = bounds.center;
        final inflated = selectionBoxWorldBounds(bounds);
        final handleWorld = camera.screenLengthToWorldLength(
          kSelectionHandleHitSize / 2,
        );
        final down = inflated.bottomRight + Offset(handleWorld, handleWorld);
        final grabOffset = down - bounds.bottomRight;
        const targetCorner = Offset(150, 150);

        pointerDown(down, alt: true);
        pointerMove(targetCorner + grabOffset, alt: true);
        pointerUp(targetCorner + grabOffset, alt: true);

        final resized = context.document.featureById(feature.id)!;
        expect(resized.bounds().center, center);
        expect(resized.size.width, 200);
        expect(resized.size.height, 200);
      },
    );

    test('shift-resize from bottom-right handle locks aspect ratio', () {
      final feature = context.document.features.first;
      context.selection.selectFeature(feature.id);

      final bounds = feature.bounds();
      final inflated = selectionBoxWorldBounds(bounds);
      final handleWorld = camera.screenLengthToWorldLength(
        kSelectionHandleHitSize / 2,
      );
      final down = inflated.bottomRight + Offset(handleWorld, handleWorld);
      final grabOffset = down - bounds.bottomRight;
      const targetCorner = Offset(200, 100);

      pointerDown(down);
      pointerMove(targetCorner + grabOffset, shift: true);
      pointerUp(targetCorner + grabOffset, shift: true);

      final resized = context.document.featureById(feature.id)!;
      expect(resized.origin, bounds.topLeft);
      expect(resized.size.width / resized.size.height, closeTo(1.0, 0.001));
      expect(resized.size.width, closeTo(200, 0.001));
      expect(resized.size.height, closeTo(200, 0.001));
    });

    test('shift-move constrains to dominant axis', () {
      pointerDown(const Offset(50, 50));
      pointerMove(const Offset(80, 55), shift: true);

      final moved = context.document.featureById(
        context.document.features.first.id,
      )!;
      expect(moved.origin.dy, closeTo(0, 0.001));
      expect(moved.origin.dx, closeTo(30, 0.001));
    });

    test('alt-drag duplicates feature and leaves original in place', () {
      final original = context.document.features.first;
      final originalId = original.id;

      pointerDown(const Offset(50, 50), alt: true);
      pointerMove(const Offset(70, 80), alt: true);
      pointerUp(const Offset(70, 80), alt: true);

      expect(context.document.features, hasLength(3));
      final unchanged = context.document.featureById(originalId)!;
      expect(unchanged.origin, Offset.zero);

      expect(context.selection.selectedFeatures, hasLength(1));
      final duplicate = context.document.featureById(
        context.selection.selectedFeatures.single,
      )!;
      expect(duplicate.id, isNot(originalId));
      expect(duplicate.origin, const Offset(20, 30));
    });

    test('alt-drag duplicates all selected features', () {
      final features = context.document.features;
      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      pointerDown(const Offset(250, 50), shift: true);
      pointerUp(const Offset(250, 50), shift: true);

      pointerDown(const Offset(50, 50), alt: true);
      pointerMove(const Offset(60, 60), alt: true);
      pointerUp(const Offset(60, 60), alt: true);

      expect(context.document.features, hasLength(4));
      expect(features[0].origin, Offset.zero);
      expect(features[1].origin, const Offset(200, 0));

      expect(context.selection.selectedFeatures, hasLength(2));
      final selectedOrigins = context.selection.selectedFeatures
          .map((id) => context.document.featureById(id)!.origin)
          .toSet();
      expect(selectedOrigins, {const Offset(10, 10), const Offset(210, 10)});
    });

    test('pressing alt mid-drag duplicates at current position', () {
      final original = context.document.features.first;
      final originalId = original.id;

      pointerDown(const Offset(50, 50));
      pointerMove(const Offset(70, 60));
      pointerMove(const Offset(70, 60), alt: true);
      pointerMove(const Offset(90, 80), alt: true);
      pointerUp(const Offset(90, 80), alt: true);

      expect(context.document.featureById(originalId)!.origin, Offset.zero);
      final duplicate = context.document.featureById(
        context.selection.selectedFeatures.single,
      )!;
      expect(duplicate.origin, const Offset(40, 30));
    });

    test('alt-click without drag does not duplicate', () {
      pointerDown(const Offset(50, 50), alt: true);
      pointerUp(const Offset(50, 50), alt: true);

      expect(context.document.features, hasLength(2));
    });

    test('shift-resize from bottom edge locks aspect ratio', () {
      final feature = context.document.features.first;
      context.selection.selectFeature(feature.id);

      final bounds = feature.bounds();
      final down = edgeHitWorldPoint(bounds, _SelectionEdge.bottom);
      final grabOffset = down - bounds.bottomRight;
      const targetBottom = Offset(50, 200);

      pointerDown(down);
      pointerMove(targetBottom + grabOffset, shift: true);
      pointerUp(targetBottom + grabOffset, shift: true);

      final resized = context.document.featureById(feature.id)!;
      expect(resized.origin.dy, closeTo(0, 0.001));
      expect(resized.size.width / resized.size.height, closeTo(1.0, 0.001));
      expect(resized.size.width, closeTo(200, 0.001));
      expect(resized.size.height, closeTo(200, 0.001));
    });

    test('alt-resize from top edge expands symmetrically around center', () {
      final feature = context.document.features.first;
      context.selection.selectFeature(feature.id);

      final bounds = feature.bounds();
      final center = bounds.center;
      final down = edgeHitWorldPoint(bounds, _SelectionEdge.top);
      final grabOffset = down - bounds.topLeft;
      const targetTop = Offset(50, -50);

      pointerDown(down, alt: true);
      pointerMove(targetTop + grabOffset, alt: true);
      pointerUp(targetTop + grabOffset, alt: true);

      final resized = context.document.featureById(feature.id)!;
      expect(resized.bounds().center, center);
      expect(resized.size.width, 100);
      expect(resized.size.height, 200);
    });

    test('edge resize does not snap on first move when grab is off-center', () {
      final feature = context.document.features.first;
      context.selection.selectFeature(feature.id);

      final bounds = feature.bounds();
      final down =
          edgeHitWorldPoint(bounds, _SelectionEdge.top) + const Offset(10, 0);

      pointerDown(down);
      pointerMove(down);

      final unchanged = context.document.featureById(feature.id)!;
      expect(unchanged.bounds(), bounds);
    });

    test('does not resize when multiple features are selected', () {
      final features = context.document.features;
      context.selection.selectFeature(features[0].id);
      context.selection.selectFeature(features[1].id);

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
      context = EditorContext(
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
      final feature = context.document.features.first;
      final endBefore =
          feature.origin +
          (feature.kind as FeatureKindPolyline).localPoints.last;

      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      expect(context.selection.selectedFeatures.single, feature.id);

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

      final resized = context.document.featureById(feature.id)!;
      final endAfter =
          resized.origin +
          (resized.kind as FeatureKindPolyline).localPoints.last;
      expect(resized.size.width, 150);
      expect(resized.size.height, 150);
      expect(endAfter, isNot(endBefore));
    });

    test('selected polyline exposes vertex handles and drags a vertex', () {
      context = polylineDocument();
      final feature = context.document.features.first;

      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      expect(context.selection.selectedFeatures.single, feature.id);

      final endBefore = polylineWorldPoints(feature).last;
      pointerDown(const Offset(100, 100));
      pointerMove(const Offset(150, 100));
      pointerUp(const Offset(150, 100));

      final moved = context.document.featureById(feature.id)!;
      expect(polylineWorldPoints(moved).last, const Offset(150, 100));
      expect(polylineWorldPoints(moved).last, isNot(endBefore));
    });

    test('does not edit vertices when multiple lines are selected', () {
      context = EditorContext(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(100, 1),
            kind: const FeatureKindPolyline([
              Offset.zero,
              Offset(100, 0),
            ], strokeColor: Color(0xFFFFFFFF)),
          ),
          Feature(
            origin: const Offset(200, 0),
            size: const Size(100, 1),
            kind: const FeatureKindPolyline([
              Offset.zero,
              Offset(100, 0),
            ], strokeColor: Color(0xFFFFFFFF)),
          ),
        ]),
      );
      final first = context.document.features[0];
      final second = context.document.features[1];
      context.selection.selectFeature(first.id);
      context.selection.selectFeature(second.id);
      final firstLocalPoints = (first.kind as FeatureKindPolyline).localPoints
          .toList();

      pointerDown(const Offset(100, 0));
      pointerMove(const Offset(150, 20));
      pointerUp(const Offset(150, 20));

      final movedFirst = context.document.featureById(first.id)!;
      expect(
        (movedFirst.kind as FeatureKindPolyline).localPoints,
        firstLocalPoints,
      );
      expect(movedFirst.origin, isNot(const Offset(0, 0)));
      expect(
        context.document.featureById(second.id)!.origin,
        isNot(const Offset(200, 0)),
      );
    });

    test('escape does not enter a line edit mode', () {
      context = polylineDocument();
      final feature = context.document.features.first;

      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      expect(keyDown(LogicalKeyboardKey.escape), isFalse);
      expect(context.selection.selectedFeatures.single, feature.id);
    });

    test('empty click clears a selected line', () {
      context = polylineDocument();

      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      pointerDown(const Offset(500, 500));
      pointerUp(const Offset(500, 500));

      expect(context.selection.selectedFeatures, isEmpty);
    });

    test('undo restores vertex geometry after edit drag', () {
      context = polylineDocument();
      final feature = context.document.features.first;

      pointerDown(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      pointerDown(const Offset(100, 100));
      pointerMove(const Offset(150, 100));
      pointerMove(const Offset(175, 125));
      expect(context.history.undoCount, 0);
      pointerUp(const Offset(175, 125));

      final afterDrag = polylineWorldPoints(
        context.document.featureById(feature.id)!,
      );
      expect(afterDrag.last, const Offset(175, 125));
      expect(context.history.undoCount, 1);

      context.undo();
      final restored = context.document.featureById(feature.id)!;
      expect(polylineWorldPoints(restored).last, const Offset(100, 100));
    });

    test(
      'double-click non-polyline does not enter a select-tool edit mode',
      () {
        pointerDown(const Offset(50, 50));
        pointerUp(const Offset(50, 50));
        pointerDown(const Offset(50, 50));
        pointerUp(const Offset(50, 50));

        final feature = context.document.features.first;
        expect(context.selection.selectedFeatures.single, feature.id);
        expect(keyDown(LogicalKeyboardKey.escape), isFalse);
        expect(context.selection.selectedFeatures.single, feature.id);
      },
    );

    test('corner resize scales text font size to fill new bounds', () {
      const contents = 'Line one\nLine two\nLine three';
      context = EditorContext(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(200, 80),
            kind: const FeatureKindText(contents, fillColor: Color(0xFFFFFFFF)),
          ),
        ]),
      );
      final feature = context.document.features.first;
      context.selection.selectFeature(feature.id);
      final initialFontSize = (feature.kind as FeatureKindText).fontSize;

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

      final resized = context.document.featureById(feature.id)!;
      final textKind = resized.kind as FeatureKindText;
      expect(resized.origin, bounds.topLeft);
      expect(resized.size.width, 300);
      expect(resized.size.height, 300);
      expect(textKind.fontSize, greaterThan(initialFontSize));
      expect(
        textKind
            .measureContents(width: 300, fontSize: textKind.fontSize)
            .height,
        lessThanOrEqualTo(300),
      );
    });

    test('vertical resize scales text font size to fill taller box', () {
      context = EditorContext(
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
      final feature = context.document.features.first;
      context.selection.selectFeature(feature.id);
      final initialFontSize = (feature.kind as FeatureKindText).fontSize;

      final bounds = feature.bounds();
      final down = edgeHitWorldPoint(bounds, _SelectionEdge.bottom);
      final grabOffset = down - bounds.bottomRight;
      const targetBottom = Offset(200, 200);

      pointerDown(down);
      pointerMove(targetBottom + grabOffset);
      pointerUp(targetBottom + grabOffset);

      final resized = context.document.featureById(feature.id)!;
      final textKind = resized.kind as FeatureKindText;
      expect(resized.size.width, 200);
      expect(resized.size.height, 200);
      expect(textKind.fontSize, greaterThan(initialFontSize));
    });

    test(
      'double-click text opens edit session without entering edit mode',
      () async {
        context = EditorContext(
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
        final feature = context.document.features.first;
        final sessions = <TextEditSession>[];
        final subscription = notifierChangesStream(context.textEdit)
            .map((_) => context.textEdit.session)
            .where((session) => session != null)
            .cast<TextEditSession>()
            .listen(sessions.add);

        doubleClick(const Offset(50, 24));
        await Future<void>.delayed(Duration.zero);

        expect(context.selection.selectedFeatures.single, feature.id);
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
      },
    );

    test('double-click polyline does not open text edit session', () async {
      context = polylineDocument();
      final sessions = <TextEditSession>[];
      final subscription = notifierChangesStream(context.textEdit)
          .map((_) => context.textEdit.session)
          .where((session) => session != null)
          .cast<TextEditSession>()
          .listen(sessions.add);

      doubleClick(const Offset(50, 50));

      expect(sessions, isEmpty);

      await subscription.cancel();
    });
  });
}
