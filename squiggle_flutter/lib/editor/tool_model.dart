import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/pan_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';
import 'package:squiggle_flutter/tools/tool.dart';

/// Holds the active editor tool and notifies observers when it repaints.
class ToolModel extends ChangeNotifier {
  ToolModel({Tool? initialTool})
    : _activeTool = initialTool ?? SelectTool(),
      _spacePanTool = PanTool();

  Tool _activeTool;
  final PanTool _spacePanTool;
  bool _isLocked = false;

  /// Whether space is currently held, making the cursor and next press pan.
  bool _isSpacePanning = false;

  /// Whether the current pointer gesture started while space was held. It
  /// stays set until pointer up so releasing space mid-drag keeps panning.
  bool _isSpacePanGesture = false;

  /// Whether the current pointer gesture is owned by [_activeTool].
  bool _isActiveToolGesture = false;

  Tool get activeTool => _activeTool;

  bool get isLocked => _isLocked;

  bool get isSpacePanning => _isSpacePanning;

  Tool get _pointerTool => _isSpacePanGesture ? _spacePanTool : _activeTool;

  bool get _showsPanCursor =>
      _isSpacePanGesture || (_isSpacePanning && !_isActiveToolGesture);

  void toggleLock() {
    _isLocked = !_isLocked;
    notifyListeners();
  }

  void beginSpacePan() {
    if (_isSpacePanning) return;
    _isSpacePanning = true;
    notifyListeners();
  }

  void endSpacePan() {
    if (!_isSpacePanning) return;
    _isSpacePanning = false;
    notifyListeners();
  }

  /// Returns to selection after creation unless automatic switching is locked.
  void resetToSelectTool(EditorContext context) {
    if (_isLocked) return;
    setTool(SelectTool(), context);
  }

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
    _isSpacePanGesture = _isSpacePanning;
    _isActiveToolGesture = !_isSpacePanGesture;
    _pointerTool.onPointerDown(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    notifyListeners();
  }

  void onDoubleClick(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    _pointerTool.onDoubleClick(context, worldPosition, camera);
    notifyListeners();
  }

  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _pointerTool.onPointerMove(
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
    _pointerTool.onPointerUp(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    _isSpacePanGesture = false;
    _isActiveToolGesture = false;
    notifyListeners();
  }

  void onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _pointerTool.onPointerHover(
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

  void cancelInteraction(EditorContext context) {
    _pointerTool.cancelInteraction(context);
    _isSpacePanGesture = false;
    _isActiveToolGesture = false;
  }

  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return _showsPanCursor
        ? _spacePanTool.resolveCursor(context, worldPosition, camera)
        : _activeTool.resolveCursor(context, worldPosition, camera);
  }
}
