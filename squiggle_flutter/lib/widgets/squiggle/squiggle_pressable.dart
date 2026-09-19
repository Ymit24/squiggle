import 'package:flutter/material.dart';

typedef SquigglePressableBuilder =
    Widget Function(BuildContext context, SquigglePressableState state);

@immutable
class SquigglePressableState {
  const SquigglePressableState({
    required this.hovered,
    required this.focused,
    required this.pressed,
    required this.enabled,
  });

  final bool hovered;
  final bool focused;
  final bool pressed;
  final bool enabled;

  bool get highlighted => hovered || focused || pressed;
}

/// Shared interaction behavior for custom Squiggle controls and surfaces.
class SquigglePressable extends StatefulWidget {
  const SquigglePressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.onDoubleTap,
    this.onSecondaryTapDown,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  final VoidCallback? onPressed;
  final VoidCallback? onDoubleTap;
  final GestureTapDownCallback? onSecondaryTapDown;
  final FocusNode? focusNode;
  final bool autofocus;
  final String? semanticLabel;
  final SquigglePressableBuilder builder;

  @override
  State<SquigglePressable> createState() => _SquigglePressableState();
}

class _SquigglePressableState extends State<SquigglePressable> {
  bool _hovered = false;
  bool _focused = false;
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final state = SquigglePressableState(
      hovered: _hovered,
      focused: _focused,
      pressed: _pressed,
      enabled: _enabled,
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel,
      child: MouseRegion(
        cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) {
          setState(() {
            _hovered = false;
            _pressed = false;
          });
        },
        child: FocusableActionDetector(
          enabled: _enabled,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed?.call();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onPressed,
            onDoubleTap: _enabled ? widget.onDoubleTap : null,
            onSecondaryTapDown: _enabled ? widget.onSecondaryTapDown : null,
            onTapDown: _enabled ? (_) => _setPressed(true) : null,
            onTapUp: _enabled ? (_) => _setPressed(false) : null,
            onTapCancel: _enabled ? () => _setPressed(false) : null,
            child: widget.builder(context, state),
          ),
        ),
      ),
    );
  }
}
