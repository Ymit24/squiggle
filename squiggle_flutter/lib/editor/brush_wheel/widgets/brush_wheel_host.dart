import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/brush_wheel/brush_wheel_geometry.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_wheel.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/drawing_tool.dart';

const _digitKeys = [
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

/// Shows the brush wheel at the pointer while B is held, and activates the
/// hovered brush when B is released.
///
/// Must wrap the editor's shortcut scope: B presses reach this widget only
/// after descendants ignore them. While open it takes primary focus, so the
/// release, digits and Escape never reach the tool shortcuts below.
class BrushWheelHost extends StatefulWidget {
  const BrushWheelHost({
    super.key,
    required this.editorContext,
    required this.imageRepository,
    required this.textEditOpen,
    required this.child,
  });

  final EditorContext editorContext;
  final ImageRepository imageRepository;
  final bool textEditOpen;
  final Widget child;

  @override
  State<BrushWheelHost> createState() => _BrushWheelHostState();
}

class _BrushWheelHostState extends State<BrushWheelHost> {
  final _focusNode = FocusNode(
    debugLabel: 'BrushWheelHost',
    skipTraversal: true,
  );
  late final AppLifecycleListener _lifecycle;

  Offset? _pointer;
  FocusNode? _restoreFocus;

  /// Non-null exactly while the wheel is open.
  Offset? _center;
  FeatureKind? _kind;
  int? _hovered;

  @override
  void initState() {
    super.initState();
    // Losing the window while B is held would otherwise strand the wheel.
    _lifecycle = AppLifecycleListener(onInactive: () => _close(commit: false));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final center = _center;
    final kind = _kind;
    final brushes = widget.editorContext.brushes;
    return MouseRegion(
      opaque: false,
      onHover: (event) => _trackPointer(event.localPosition),
      onExit: (_) => _trackPointer(null),
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKeyEvent,
        onFocusChange: (focused) {
          if (!focused) _close(commit: false);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.child,
            if (center != null && kind != null)
              // Absorbs canvas input but still counts as a hit, so the
              // MouseRegion above keeps tracking the pointer.
              AbsorbPointer(
                child: Stack(
                  children: [
                    Positioned(
                      left: center.dx - BrushWheelGeometry.outerRadius,
                      top: center.dy - BrushWheelGeometry.outerRadius,
                      child: BrushWheel(
                        brushes: brushes.profiles,
                        activeId: brushes.active.id,
                        hoveredIndex: _hovered,
                        kind: kind,
                        imageRepository: widget.imageRepository,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;
    if (_center == null) {
      if (key == LogicalKeyboardKey.keyB && event is KeyDownEvent && _open()) {
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }
    if (key == LogicalKeyboardKey.keyB && event is KeyUpEvent) {
      _close(commit: true);
    } else if (key == LogicalKeyboardKey.escape && event is KeyDownEvent) {
      _close(commit: false);
    } else if (_digitKeys.indexOf(key) case final index
        when index >= 0 && event is KeyDownEvent) {
      if (index < widget.editorContext.brushes.profiles.length) {
        setState(() => _hovered = index);
      }
    }
    // The wheel is modal while B is held.
    return KeyEventResult.handled;
  }

  /// Mirrors the Cmd/Ctrl+number brush shortcut: brushes only apply to new
  /// drawings, so the wheel is unavailable with a selection or a non-drawing
  /// tool.
  bool _open() {
    final editor = widget.editorContext;
    final keyboard = HardwareKeyboard.instance;
    if (widget.textEditOpen ||
        keyboard.isMetaPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        editor.selection.selectedNodeIds.isNotEmpty) {
      return false;
    }
    if (editor.tool.activeTool is! DrawingTool) return false;
    final tool = editor.tool.activeTool as DrawingTool;
    final size = context.size ?? Size.zero;
    final pointer = _pointer ?? size.center(Offset.zero);
    setState(() {
      _kind = tool.createDrawingKind();
      _center = BrushWheelGeometry.clampCenter(pointer, size);
      _hovered = _slotAt(pointer);
    });
    _restoreFocus = FocusManager.instance.primaryFocus;
    _focusNode.requestFocus();
    return true;
  }

  void _close({required bool commit}) {
    if (_center == null) return;
    final hovered = _hovered;
    if (commit && hovered != null) {
      final brushes = widget.editorContext.brushes;
      // activate() ignores the already active brush.
      brushes.activate(brushes.profiles[hovered].id);
    }
    setState(() {
      _center = null;
      _kind = null;
      _hovered = null;
    });
    final restore = _restoreFocus;
    _restoreFocus = null;
    if (_focusNode.hasFocus && restore != null && restore.context != null) {
      restore.requestFocus();
    }
  }

  void _trackPointer(Offset? position) {
    _pointer = position;
    if (_center == null) return;
    final hovered = position == null ? null : _slotAt(position);
    if (hovered != _hovered) setState(() => _hovered = hovered);
  }

  int? _slotAt(Offset position) {
    final center = _center;
    if (center == null) return null;
    return BrushWheelGeometry.slotAt(
      position - center,
      widget.editorContext.brushes.profiles.length,
    );
  }
}
