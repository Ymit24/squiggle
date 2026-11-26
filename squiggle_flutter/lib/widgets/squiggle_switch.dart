import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';

const _trackWidth = 36.0;
const _trackHeight = 20.0;
const _thumbInset = 3.0;
const _duration = Duration(milliseconds: 120);

/// Compact desktop-style on/off switch themed with Squiggle's color tokens.
class SquiggleSwitch extends StatefulWidget {
  const SquiggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<SquiggleSwitch> createState() => _SquiggleSwitchState();
}

class _SquiggleSwitchState extends State<SquiggleSwitch> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.squiggleTheme.colors;
    final radius = BorderRadius.circular(_trackHeight / 2);

    return Semantics(
      toggled: widget.value,
      onTap: _toggle,
      child: FocusableActionDetector(
        onShowFocusHighlight: (focused) => setState(() => _focused = focused),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _toggle(),
          ),
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: _toggle,
            child: AnimatedContainer(
              duration: _duration,
              width: _trackWidth,
              height: _trackHeight,
              padding: const EdgeInsets.all(_thumbInset),
              decoration: BoxDecoration(
                color: _trackColor(colors),
                borderRadius: radius,
                border: _focused ? Border.all(color: colors.accent) : null,
              ),
              child: AnimatedAlign(
                duration: _duration,
                curve: Curves.easeOut,
                alignment: widget.value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: _trackHeight - _thumbInset * 2,
                  height: _trackHeight - _thumbInset * 2,
                  decoration: BoxDecoration(
                    color: widget.value ? colors.base : colors.subtext0,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggle() => widget.onChanged(!widget.value);

  Color _trackColor(SquiggleColorScheme colors) =>
      switch ((widget.value, _hovered)) {
        (true, true) => colors.text.withValues(alpha: 0.85),
        (true, false) => colors.text,
        (false, true) => Color.lerp(colors.surface1, colors.subtext0, 0.15)!,
        (false, false) => colors.surface1,
      };
}
