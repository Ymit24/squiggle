import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

enum SelectionEdge { top, right, bottom, left }

class SelectToolTestHarness {
  SelectToolTestHarness({EditorContext? context})
    : context = context ?? defaultContext(),
      camera = Camera();

  EditorContext context;
  final Camera camera;

  static EditorContext defaultContext() => EditorContext(
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

  static EditorContext polylineContext() => EditorContext(
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

  void pointerDown(Offset world, {bool shift = false, bool alt = false}) {
    context.tool.onPointerDown(
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

  void pointerUp(Offset world, {bool shift = false, bool alt = false}) {
    context.tool.onPointerUp(
      context,
      world,
      camera,
      isShiftPressed: shift,
      isAltPressed: alt,
    );
  }

  void click(Offset world, {bool shift = false, bool alt = false}) {
    pointerDown(world, shift: shift, alt: alt);
    pointerUp(world, shift: shift, alt: alt);
  }

  void doubleClick(Offset world) {
    click(world);
    context.tool.onDoubleClick(context, world, camera);
  }

  bool keyDown(LogicalKeyboardKey key) => context.tool.onKeyEvent(
    context,
    KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.enter,
      logicalKey: key,
      timeStamp: Duration.zero,
    ),
  );

  Offset cornerHitWorldPoint(Rect bounds) {
    final selectionBounds = bounds.inflate(kSelectionBoxPadding);
    final hitRadius = camera.screenLengthToWorldLength(
      kSelectionHandleHitSize / 2,
    );
    return selectionBounds.bottomRight + Offset(hitRadius, hitRadius);
  }

  Offset edgeHitWorldPoint(Rect bounds, SelectionEdge edge) {
    final screenBounds = camera
        .worldToScreenBounds(bounds)
        .inflate(kSelectionBoxPadding);
    final half = kSelectionHandleHitSize / 2;
    final screenPoint = switch (edge) {
      SelectionEdge.top => Offset(
        screenBounds.center.dx,
        screenBounds.top - half,
      ),
      SelectionEdge.right => Offset(
        screenBounds.right - half,
        screenBounds.center.dy,
      ),
      SelectionEdge.bottom => Offset(
        screenBounds.center.dx,
        screenBounds.bottom - half,
      ),
      SelectionEdge.left => Offset(
        screenBounds.left - half,
        screenBounds.center.dy,
      ),
    };
    return camera.screenToWorld(screenPoint);
  }
}

List<Offset> polylineWorldPoints(Feature feature) {
  final kind = feature.kind as FeatureKindPolyline;
  return worldPoints(feature.origin, kind.localPoints);
}
