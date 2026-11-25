import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/pan_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

void main() {
  test('PanTool pans the camera in screen space', () {
    final context = EditorContext(document: Document());
    addTearDown(context.dispose);
    final camera = context.camera..zoom = 2;
    final tool = PanTool();

    expect(tool.resolveCursor(context, Offset.zero, camera), EditorCursor.grab);

    tool.onPointerDown(
      context,
      camera.screenToWorld(const Offset(10, 20)),
      camera,
      isShiftPressed: false,
      isAltPressed: false,
    );
    expect(
      tool.resolveCursor(context, Offset.zero, camera),
      EditorCursor.grabbing,
    );

    tool.onPointerMove(
      context,
      camera.screenToWorld(const Offset(30, 50)),
      camera,
      isShiftPressed: false,
      isAltPressed: false,
    );
    expect(camera.location, const Offset(-40, -60));

    tool.onPointerMove(
      context,
      camera.screenToWorld(const Offset(40, 60)),
      camera,
      isShiftPressed: false,
      isAltPressed: false,
    );
    expect(camera.location, const Offset(-60, -80));

    tool.onPointerUp(
      context,
      camera.screenToWorld(const Offset(40, 60)),
      camera,
      isShiftPressed: false,
      isAltPressed: false,
    );
    expect(tool.resolveCursor(context, Offset.zero, camera), EditorCursor.grab);
  });

  test('space pan does not change the active tool or selection', () {
    final context = EditorContext(
      document: Document.fromFeatures([
        Feature(
          origin: const Offset(0, 0),
          size: const Size(10, 10),
          kind: FeatureKindRectangle(),
        ),
      ]),
    );
    addTearDown(context.dispose);
    final camera = context.camera;
    final selectTool = SelectTool();
    context.setTool(selectTool);
    final nodeId = context.document.nodes.single.id;
    context.selection.setSelection([nodeId]);

    context.tool.beginSpacePan();
    context.tool.onPointerDown(
      context,
      camera.screenToWorld(Offset.zero),
      camera,
      isShiftPressed: false,
      isAltPressed: false,
    );

    // Releasing space mid-drag keeps the gesture on the pan tool.
    context.tool.endSpacePan();
    context.tool.onPointerMove(
      context,
      camera.screenToWorld(const Offset(50, 40)),
      camera,
      isShiftPressed: false,
      isAltPressed: false,
    );
    context.tool.onPointerUp(
      context,
      camera.screenToWorld(const Offset(50, 40)),
      camera,
      isShiftPressed: false,
      isAltPressed: false,
    );

    expect(context.tool.activeTool, same(selectTool));
    expect(context.selection.selectedNodeIds, [nodeId]);
    expect(camera.location, const Offset(-50, -40));
  });
}
