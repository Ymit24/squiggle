import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/select_tool.dart';

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

    test('click without drag from idle enters placing without creating feature', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(context.document.features, isEmpty);
    });

    test('two clicks then Enter commits polyline with 2 points', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));
      pointerDown(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      expect(context.document.features, isEmpty);

      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);

      final features = context.document.features;
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindPolyline>());
      expect(
        worldPointsFor(features.first),
        [const Offset(0, 0), const Offset(100, 100)],
      );
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

      expect(
        worldPointsFor(context.document.features.first),
        [
          const Offset(0, 0),
          const Offset(100, 0),
          const Offset(100, 100),
        ],
      );
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

      expect(context.document.features, hasLength(1));
    });

    test('Enter or Escape with 1 point discards without creating feature', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);
      expect(context.document.features, isEmpty);

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      expect(finishWithKey(LogicalKeyboardKey.escape), isTrue);
      expect(context.document.features, isEmpty);
    });

    test('drag from idle commits 2-point line on pointer up', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerMove(const Offset(50, 50));
      pointerUp(const Offset(50, 50));

      final features = context.document.features;
      expect(features, hasLength(1));
      expect(features.first.kind, isA<FeatureKindPolyline>());
      expect(
        worldPointsFor(features.first),
        [const Offset(0, 0), const Offset(50, 50)],
      );
    });

    test('click then drag in placing mode adds point at release position', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));

      pointerDown(const Offset(50, 50));
      pointerMove(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      expect(context.document.features, isEmpty);

      expect(finishWithKey(LogicalKeyboardKey.enter), isTrue);

      expect(
        worldPointsFor(context.document.features.first),
        [const Offset(0, 0), const Offset(100, 100)],
      );
    });

    test('deactivate mid-placement discards partial line', () {
      activateLineTool();

      pointerDown(const Offset(0, 0));
      pointerUp(const Offset(0, 0));
      pointerDown(const Offset(100, 100));
      pointerUp(const Offset(100, 100));

      context.setTool(SelectTool());

      expect(context.document.features, isEmpty);
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

      final points = worldPointsFor(context.document.features.first);
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

      final points = worldPointsFor(context.document.features.first);
      expect(points.last.dx, closeTo(points.last.dy, 0.001));
    });
  });

  group('localPointsFromWorld', () {
    test('returns empty list for empty world points', () {
      expect(localPointsFromWorld([], Offset.zero), isEmpty);
    });

    test('converts world points relative to reference', () {
      expect(
        localPointsFromWorld(
          [const Offset(10, 20), const Offset(110, 120)],
          const Offset(10, 20),
        ),
        [Offset.zero, const Offset(100, 100)],
      );
    });
  });
}
