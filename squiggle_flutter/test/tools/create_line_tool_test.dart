import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

void main() {
  group('CreateLineTool via EditorContext', () {
    late EditorContext context;
    late Camera camera;

    setUp(() {
      context = EditorContext(document: Document());
      camera = Camera();
    });

    void activateLineTool() {
      context.setTool(CreateLineTool());
    }

    void pointerDown(Offset world, {bool shift = false}) {
      context.tool.onPointerDown(
        context,
        world,
        camera,
        isShiftPressed: shift,
        isAltPressed: false,
      );
    }

    void pointerMove(Offset world, {bool shift = false}) {
      context.tool.onPointerMove(
        context,
        world,
        camera,
        isShiftPressed: shift,
        isAltPressed: false,
      );
    }

    void pointerUp(Offset world, {bool shift = false}) {
      context.tool.onPointerUp(
        context,
        world,
        camera,
        isShiftPressed: shift,
        isAltPressed: false,
      );
    }

    void pointerHover(Offset world, {bool shift = false}) {
      context.tool.onPointerHover(
        context,
        world,
        camera,
        isShiftPressed: shift,
        isAltPressed: false,
      );
    }

    bool finishWithKey(LogicalKeyboardKey key) {
      return context.tool.onKeyEvent(
        context,
        KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.enter,
          logicalKey: key,
          timeStamp: Duration.zero,
        ),
      );
    }

    List<Offset> worldPointsFor(Feature feature) {
      final kind = feature.kind as FeatureKindPolyline;
      return worldPoints(feature.origin, kind.localPoints);
    }

    test(
      'click without drag from idle enters placing without creating feature',
      () {
        activateLineTool();

        pointerDown(const Offset(0, 0));
        pointerUp(const Offset(0, 0));

        expect(context.document.nodes, isEmpty);
        expect(context.tool.activeTool, isA<CreateLineTool>());
      },
    );

    test('locked lines reset between drag, Enter and Escape completion', () {
      context.tool.toggleLock();
      activateLineTool();
      final lineTool = context.tool.activeTool;

      pointerDown(Offset.zero);
      pointerMove(const Offset(100, 100));
      pointerUp(const Offset(100, 100));
      expect(context.tool.activeTool, same(lineTool));
      expect(context.document.nodes, hasLength(1));
      expect(context.selection.isEmpty, isTrue);
      final previousId = context.document.nodes.first.id;
      context.selection.setSelection([previousId]);

      for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.escape]) {
        pointerDown(const Offset(200, 200));
        pointerUp(const Offset(200, 200));
        pointerDown(const Offset(300, 300));
        pointerUp(const Offset(300, 300));
        expect(finishWithKey(key), isTrue);
        expect(context.tool.activeTool, same(lineTool));
        expect(worldPointsFor(context.document.nodes.last as Feature), [
          const Offset(200, 200),
          const Offset(300, 300),
        ]);
      }
      expect(context.document.nodes, hasLength(3));
      expect(context.selection.selectedNodeIds, [previousId]);
    });

    test('two clicks then Enter commits polyline with 2 points', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));
      pointerDown(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      expect(context.document.nodes, isEmpty);

      expect(context.tool.activeTool, isA<CreateLineTool>());
      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);
      expect(context.tool.activeTool, isA<SelectTool>());

      final features = context.document.nodes.cast<Feature>();
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindPolyline>());
      expect(context.selection.selectedNodeIds, [features.first.id]);
      expect(worldPointsFor(features.first), [
        const Offset(0, 0),
        const Offset(100, 100),
      ]);
    });

    test('three clicks then Enter commits polyline with 3 points', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));
      pointerDown(const Offset(100, 0));
      pointerUp(const Offset(100, 0));
      pointerDown(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);

      expect(worldPointsFor((context.document.nodes.first as Feature)), [
        const Offset(0, 0),
        const Offset(100, 0),
        const Offset(100, 100),
      ]);
    });

    test('three clicks then Escape commits polyline with 3 points', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));
      pointerDown(const Offset(100, 0));
      pointerUp(const Offset(100, 0));
      pointerDown(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      expect(finishWithKey(LogicalKeyboardKey.escape), isTrue);
      expect(context.tool.activeTool, isA<SelectTool>());

      expect(context.document.nodes, hasLength(1));
    });

    test('Enter or Escape with 1 point discards without creating feature', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);
      expect(context.document.nodes, isEmpty);
      expect(context.selection.isEmpty, isTrue);
      expect(context.tool.activeTool, isA<SelectTool>());

      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(finishWithKey(LogicalKeyboardKey.escape), isTrue);
      expect(context.document.nodes, isEmpty);
    });

    test('drag from idle commits 2-point line on pointer up', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(50, 50));
      pointerUp(const Offset(50, 50));
      expect(context.tool.activeTool, isA<SelectTool>());

      final features = context.document.nodes.cast<Feature>();
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindPolyline>());
      expect(context.selection.selectedNodeIds, [features.first.id]);
      expect(worldPointsFor(features.first), [
        const Offset(0, 0),
        const Offset(50, 50),
      ]);
    });

    test('click then drag in placing mode adds point at release position', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      pointerDown(const Offset(50, 50));
      pointerMove(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      expect(context.document.nodes, isEmpty);

      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);

      expect(worldPointsFor((context.document.nodes.first as Feature)), [
        const Offset(0, 0),
        const Offset(100, 100),
      ]);
    });

    test(
      'initial click uses press position; placement uses release position',
      () {
        activateLineTool();
        camera.zoom = 2;
        final movement = camera.screenLengthToWorldLength(kTouchSlop);

        pointerDown(Offset.zero);
        pointerMove(Offset(movement, 0));
        pointerUp(Offset(movement, 0));
        expect(context.document.nodes, isEmpty);

        pointerDown(const Offset(100, 0));
        pointerMove(Offset(100 + movement, 0));
        pointerUp(Offset(100 + movement, 0));
        finishWithKey(LogicalKeyboardKey.enter);

        expect(worldPointsFor(context.document.nodes.single as Feature), [
          Offset.zero,
          Offset(100 + movement, 0),
        ]);
      },
    );

    test('placement uses release position without a move event', () {
      activateLineTool();
      pointerDown(Offset.zero);
      pointerUp(Offset.zero);
      pointerDown(const Offset(100, 0));
      pointerUp(const Offset(103, 0));
      pointerDown(const Offset(200, 0));
      pointerUp(const Offset(203, 0));
      expect(context.document.nodes, isEmpty);
      finishWithKey(LogicalKeyboardKey.enter);
      expect(worldPointsFor(context.document.nodes.single as Feature), [
        Offset.zero,
        const Offset(103, 0),
        const Offset(203, 0),
      ]);
    });

    test('placement snaps using release position and release-time Shift', () {
      activateLineTool();
      pointerDown(Offset.zero);
      pointerUp(Offset.zero);
      pointerDown(const Offset(100, 0));
      pointerUp(const Offset(103, 95), shift: true);
      final snapped = snapPointTo45DegreeAngle(
        Offset.zero,
        const Offset(103, 95),
      );
      pointerDown(const Offset(200, 100), shift: true);
      pointerMove(const Offset(250, 195), shift: true);
      pointerUp(const Offset(253, 195));
      finishWithKey(LogicalKeyboardKey.enter);
      expect(worldPointsFor(context.document.nodes.single as Feature), [
        Offset.zero,
        snapped,
        const Offset(253, 195),
      ]);
    });

    test('unmatched releases do not place vertices', () {
      activateLineTool();
      pointerDown(Offset.zero);
      pointerUp(Offset.zero);
      pointerUp(const Offset(50, 0));
      pointerDown(const Offset(100, 0));
      pointerUp(const Offset(100, 0));
      pointerUp(const Offset(150, 0));
      finishWithKey(LogicalKeyboardKey.enter);
      expect(worldPointsFor(context.document.nodes.single as Feature), [
        Offset.zero,
        const Offset(100, 0),
      ]);
    });

    test('movement beyond zoom-adjusted slop starts a line drag', () {
      activateLineTool();
      camera.zoom = 2;
      final end = Offset(camera.screenLengthToWorldLength(kTouchSlop) + 1, 0);
      pointerDown(Offset.zero);
      pointerMove(end);
      pointerUp(end);
      expect(worldPointsFor(context.document.nodes.single as Feature), [
        Offset.zero,
        end,
      ]);
    });

    test('placement uses release after moving away and back', () {
      activateLineTool();
      pointerDown(Offset.zero);
      pointerUp(Offset.zero);
      pointerDown(const Offset(100, 0));
      pointerMove(const Offset(200, 0));
      pointerMove(const Offset(101, 0));
      pointerUp(const Offset(102, 0));
      finishWithKey(LogicalKeyboardKey.enter);
      expect(worldPointsFor(context.document.nodes.single as Feature), [
        Offset.zero,
        const Offset(102, 0),
      ]);
    });

    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.escape]) {
      for (final drag in [false, true]) {
        test(
          'finish with ${key.keyLabel} during placement press (drag: $drag)',
          () {
            activateLineTool();
            pointerDown(Offset.zero);
            pointerUp(Offset.zero);
            pointerDown(const Offset(100, 0));
            pointerUp(const Offset(100, 0));
            pointerHover(const Offset(200, 0));
            pointerDown(const Offset(200, 0));
            if (drag) pointerMove(const Offset(300, 0));
            expect(finishWithKey(key), isTrue);
            pointerUp(const Offset(300, 0));
            expect(worldPointsFor(context.document.nodes.single as Feature), [
              Offset.zero,
              const Offset(100, 0),
            ]);
          },
        );
      }
    }

    for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.escape]) {
      test('${key.keyLabel} discards the pending initial press', () {
        activateLineTool();
        pointerDown(Offset.zero);
        expect(finishWithKey(key), isTrue);
        expect(context.tool.activeTool, isA<SelectTool>());
        pointerUp(const Offset(100, 0));
        expect(context.document.nodes, isEmpty);
        expect(finishWithKey(key), isFalse);
      });
    }

    test('finish keys are unhandled while idle or dragging a new line', () {
      activateLineTool();
      expect(finishWithKey(LogicalKeyboardKey.enter), isFalse);
      expect(finishWithKey(LogicalKeyboardKey.escape), isFalse);
      pointerDown(Offset.zero);
      pointerMove(const Offset(100, 0));
      expect(finishWithKey(LogicalKeyboardKey.enter), isFalse);
      expect(finishWithKey(LogicalKeyboardKey.escape), isFalse);
      pointerUp(const Offset(100, 0));
      expect(context.document.nodes, hasLength(1));
    });

    test('release position and Shift determine the dragged endpoint', () {
      activateLineTool();
      pointerDown(Offset.zero);
      pointerMove(const Offset(100, 0));
      pointerUp(const Offset(200, 195), shift: true);
      expect(worldPointsFor(context.document.nodes.single as Feature), [
        Offset.zero,
        snapPointTo45DegreeAngle(Offset.zero, const Offset(200, 195)),
      ]);
    });

    test('cancel discards placement and the next gesture starts fresh', () {
      activateLineTool();
      pointerDown(Offset.zero);
      pointerUp(Offset.zero);
      pointerDown(const Offset(100, 0));
      pointerUp(const Offset(100, 0));
      context.cancelInteraction();
      expect(context.document.nodes, isEmpty);
      pointerDown(const Offset(200, 0));
      pointerMove(const Offset(300, 0));
      pointerUp(const Offset(300, 0));
      expect(worldPointsFor(context.document.nodes.single as Feature), [
        const Offset(200, 0),
        const Offset(300, 0),
      ]);
      context.undo();
      expect(context.document.nodes, isEmpty);
      context.redo();
      expect(context.document.nodes, hasLength(1));
    });

    test('deactivate mid-placement discards partial line', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));
      pointerDown(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      context.setTool(SelectTool());

      expect(context.document.nodes, isEmpty);
    });

    test('hover updates preview while placing', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(() => pointerHover(const Offset(200, 200)), returnsNormally);
    });

    test('shift-drag snaps line to 45 degree angle', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(100, 95), shift: true);
      pointerUp(const Offset(100, 95), shift: true);

      final points = worldPointsFor((context.document.nodes.first as Feature));
      expect(points.first, const Offset(0, 0));
      expect(points.last.dx, closeTo(points.last.dy, 0.001));
    });

    test('shift-click snaps second point to 45 degrees', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));
      pointerDown(const Offset(100, 95), shift: true);
      pointerUp(const Offset(100, 95), shift: true);

      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);

      final points = worldPointsFor((context.document.nodes.first as Feature));
      expect(points.last.dx, closeTo(points.last.dy, 0.001));
    });
  });

  group('localPointsFromWorld', () {
    test('returns empty list for empty world points', () {
      expect(localPointsFromWorld([], Offset.zero), isEmpty);
    });

    test('converts world points relative to reference', () {
      expect(
        localPointsFromWorld([
          const Offset(10, 20),
          const Offset(110, 120),
        ], const Offset(10, 20)),
        [Offset.zero, const Offset(100, 100)],
      );
    });
  });
}
