import 'package:flutter/material.dart';

typedef SquigglePressableBuilder =
    Widget Function(BuildContext context, SquigglePressableState state);

@immutable
class SquigglePressableState {
  const SquigglePressableState({
    required this.isEnabled,
    required this.isHovered,
    required this.isFocused,
  });

  final bool isEnabled;
  final bool isHovered;
  final bool isFocused;

  bool get isHighlighted => isHovered || isFocused;
}

/// A theme-agnostic pressable that provides interaction state to its builder.
class SquigglePressable extends StatefulWidget {
  const SquigglePressable({
    super.key,
    required this.onPressed,
    required this.builder,
    this.behavior = HitTestBehavior.opaque,
    this.autofocus = false,
    this.focusNode,
  });

  final VoidCallback? onPressed;
  final SquigglePressableBuilder builder;
  final HitTestBehavior behavior;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<SquigglePressable> createState() => _SquigglePressableState();
}

class _SquigglePressableState extends State<SquigglePressable> {
  bool _isHovered = false;
  bool _isFocused = false;

  bool get _isEnabled => widget.onPressed != null;

  @override
  Widget build(BuildContext context) {
    final state = SquigglePressableState(
      isEnabled: _isEnabled,
      isHovered: _isEnabled && _isHovered,
      isFocused: _isEnabled && _isFocused,
    );

    return Semantics(
      button: true,
      enabled: _isEnabled,
      child: FocusableActionDetector(
        enabled: _isEnabled,
        autofocus: widget.autofocus,
        focusNode: widget.focusNode,
        mouseCursor: _isEnabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onShowHoverHighlight: (value) => setState(() => _isHovered = value),
        onShowFocusHighlight: (value) => setState(() => _isFocused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onPressed?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: widget.behavior,
          excludeFromSemantics: true,
          onTap: widget.onPressed,
          child: widget.builder(context, state),
        ),
      ),
    );
  }
}
