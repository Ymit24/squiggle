import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/pan_tool.dart';

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
}
