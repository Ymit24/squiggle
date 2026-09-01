import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';
import 'package:squiggle_flutter/tools/tool.dart';

/// Holds the active editor tool and notifies observers when it repaints.
class ToolModel extends ChangeNotifier {
  ToolModel({Tool? initialTool}) : _activeTool = initialTool ?? SelectTool();

  Tool _activeTool;

  Tool get activeTool => _activeTool;

  void setTool(Tool tool, EditorContext context) {
    if (identical(_activeTool, tool)) return;
    _activeTool.deactivate(context);
    _activeTool = tool;
    notifyListeners();
  }

  void onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _activeTool.onPointerDown(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    notifyListeners();
  }

  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _activeTool.onPointerMove(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    notifyListeners();
  }

  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _activeTool.onPointerUp(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    notifyListeners();
  }

  void onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _activeTool.onPointerHover(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    notifyListeners();
  }

  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    final handled = _activeTool.onKeyEvent(context, event);
    if (handled) {
      notifyListeners();
    }
    return handled;
  }

  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return _activeTool.resolveCursor(context, worldPosition, camera);
  }
}
