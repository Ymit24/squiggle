import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/brush_wheel/brush_wheel_geometry.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_wheel.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/brush_name_dialog.dart';
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

  bool get _isOpen => _center != null;

  int get _brushCount => widget.editorContext.brushes.profiles.length;

  /// The wheel ends with a "new brush" slot until the document is full.
  int get _slotCount =>
      _brushCount + (widget.editorContext.brushes.canCreate ? 1 : 0);

  /// Mirrors the Cmd/Ctrl+number brush shortcut: brushes only apply to new
  /// drawings, so the wheel is unavailable with a selection or a non-drawing
  /// tool.
  bool get _canOpen {
    final keyboard = HardwareKeyboard.instance;
    final hasModifier =
        keyboard.isMetaPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed;

    return !widget.textEditOpen &&
        !hasModifier &&
        widget.editorContext.selection.selectedNodeIds.isEmpty &&
        widget.editorContext.tool.activeTool is DrawingTool;
  }

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
          if (!focused) {
            _close(commit: false);
          }
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
                        canCreate: brushes.canCreate,
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
    if (_isOpen) {
      _onKeyEventWhileOpen(event);

      // The wheel is modal while B is held.
      return KeyEventResult.handled;
    }

    final opensWheel =
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyB &&
        _open();

    return opensWheel ? KeyEventResult.handled : KeyEventResult.ignored;
  }

  void _onKeyEventWhileOpen(KeyEvent event) {
    final key = event.logicalKey;

    if (event is KeyUpEvent) {
      if (key == LogicalKeyboardKey.keyB) {
        _close(commit: true);
      }

      return;
    }

    if (event is! KeyDownEvent) {
      return;
    }

    if (key == LogicalKeyboardKey.escape) {
      _close(commit: false);

      return;
    }

    final index = _digitKeys.indexOf(key);
    final hasBrush = index >= 0 && index < _brushCount;

    if (hasBrush) {
      setState(() => _hovered = index);
    }
  }

  bool _open() {
    if (!_canOpen) {
      return false;
    }

    final tool = widget.editorContext.tool.activeTool as DrawingTool;
    final size = context.size ?? Size.zero;
    final pointer = _pointer ?? size.center(Offset.zero);

    // Focus moves to the wheel so the release, digits and Escape stay out of
    // the tool shortcuts. The previous focus is restored on close.
    _restoreFocus = FocusManager.instance.primaryFocus;
    _focusNode.requestFocus();

    setState(() {
      _kind = tool.createDrawingKind();
      _center = BrushWheelGeometry.clampCenter(pointer, size);
      _hovered = _slotAt(pointer);
    });

    return true;
  }

  void _close({required bool commit}) {
    if (!_isOpen) {
      return;
    }

    final hovered = _hovered;

    var createBrush = false;

    if (commit && hovered != null) {
      final brushes = widget.editorContext.brushes;

      if (hovered >= _brushCount) {
        createBrush = brushes.canCreate;
      } else {
        // activate() ignores the already active brush.
        brushes.activate(brushes.profiles[hovered].id);
      }
    }

    setState(() {
      _center = null;
      _kind = null;
      _hovered = null;
    });

    _restorePreviousFocus();

    if (createBrush) {
      _createBrush();
    }
  }

  /// Same flow as the inspector's Create brush item.
  Future<void> _createBrush() async {
    final brushes = widget.editorContext.brushes;
    final sourceId = brushes.active.id;
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const BrushNameDialog(creating: true),
    );

    if (!mounted ||
        name == null ||
        brushes.active.id != sourceId ||
        !brushes.canCreate) {
      return;
    }

    brushes.create(name);
  }

  void _restorePreviousFocus() {
    final previous = _restoreFocus;
    _restoreFocus = null;

    final canRestore =
        _focusNode.hasFocus && previous != null && previous.context != null;

    if (canRestore) {
      previous.requestFocus();
    }
  }

  void _trackPointer(Offset? position) {
    _pointer = position;

    if (!_isOpen) {
      return;
    }

    final hovered = position == null ? null : _slotAt(position);

    if (hovered != _hovered) {
      setState(() => _hovered = hovered);
    }
  }

  int? _slotAt(Offset position) {
    final center = _center;

    if (center == null) {
      return null;
    }

    return BrushWheelGeometry.slotAt(position - center, _slotCount);
  }
}
