import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/pan_tool.dart';
import 'package:squiggle_flutter/tools/select_tool.dart';

void main() {
  group('PanTool via EditorContext', () {
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

    void pointerMove(Offset world) {
      context.tool.onPointerMove(
        context,
        world,
        camera,
        isShiftPressed: false,
        isAltPressed: false,
      );
    }

    void pointerUp(Offset world) {
      context.tool.onPointerUp(
        context,
        world,
        camera,
        isShiftPressed: false,
        isAltPressed: false,
      );
    }

    EditorCursor cursorAt(Offset world) {
      return context.tool.resolveCursor(context, world, camera);
    }

    test('drag pans the camera by the world delta', () {
      context.setTool(PanTool());
      camera.location = const Offset(100, 100);
      camera.zoom = 2;

      final startWorld = camera.screenToWorld(const Offset(50, 0));
      final endWorld = camera.screenToWorld(const Offset(150, 0));

      pointerDown(startWorld);
      pointerMove(endWorld);
      pointerUp(endWorld);

      expect(camera.location, const Offset(-100, 100));
    });

    test('grab point stays fixed under the cursor while panning', () {
      context.setTool(PanTool());
      camera.location = const Offset(100, 100);
      camera.zoom = 2;

      final startScreen = const Offset(50, 0);
      final endScreen = const Offset(150, 0);
      final startWorld = camera.screenToWorld(startScreen);

      pointerDown(startWorld);
      pointerMove(camera.screenToWorld(endScreen));

      expect(camera.worldToScreen(startWorld), endScreen);
    });

    test('slow incremental drags pan smoothly without jitter', () {
      context.setTool(PanTool());
      camera.location = const Offset(100, 100);
      camera.zoom = 2;

      final startScreen = const Offset(50, 0);
      final startWorld = camera.screenToWorld(startScreen);
      pointerDown(startWorld);

      final locations = <Offset>[];
      for (var x = 51; x <= 150; x += 3) {
        // Mirror the viewport: each move's world position is derived from the
        // camera's current (already-panned) location.
        final world = camera.screenToWorld(Offset(x.toDouble(), 0));
        pointerMove(world);
        locations.add(camera.location);
        expect(camera.worldToScreen(startWorld), Offset(x.toDouble(), 0));
      }

      for (var i = 1; i < locations.length; i++) {
        expect(locations[i].dx, lessThan(locations[i - 1].dx));
        expect(locations[i].dy, locations[i - 1].dy);
      }
    });

    test('zoom during a pan drag keeps the grab point under the cursor', () {
      context.setTool(PanTool());
      camera.location = const Offset(100, 100);
      camera.zoom = 2;

      final startWorld = camera.screenToWorld(const Offset(50, 0));
      pointerDown(startWorld);

      pointerMove(camera.screenToWorld(const Offset(60, 0)));

      // Scroll-zoom anchored at the cursor's position mid-drag.
      camera.zoomToward(const Offset(60, 0), 2.0);

      for (var x = 61; x <= 80; x += 3) {
        final world = camera.screenToWorld(Offset(x.toDouble(), 0));
        pointerMove(world);
        expect(camera.worldToScreen(startWorld), Offset(x.toDouble(), 0));
      }
    });

    test('reports grab cursor idle and grabbing while dragging', () {
      context.setTool(PanTool());

      expect(cursorAt(Offset.zero), EditorCursor.grab);

      pointerDown(Offset.zero);
      expect(cursorAt(Offset.zero), EditorCursor.grabbing);

      pointerUp(const Offset(100, 0));
      expect(cursorAt(Offset.zero), EditorCursor.grab);
    });

    test('switching tools mid-drag resets the pan state', () {
      context.setTool(PanTool());

      pointerDown(Offset.zero);
      context.setTool(SelectTool());

      expect(cursorAt(Offset.zero), EditorCursor.basic);
    });
  });
}
