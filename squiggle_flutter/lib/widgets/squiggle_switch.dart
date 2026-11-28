import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// Compact desktop-style on/off switch themed with Squiggle's color tokens.
class SquiggleSwitch extends StatefulWidget {
  const SquiggleSwitch({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  /// Accessible name announced with the on/off state.
  final String label;
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
    final theme = context.squiggleTheme;
    final switches = theme.switches;
    final colors = theme.colors;
    final radius = BorderRadius.circular(switches.trackHeight / 2);

    return Semantics(
      label: widget.label,
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
              duration: switches.transitionDuration,
              width: switches.trackWidth,
              height: switches.trackHeight,
              padding: EdgeInsets.all(switches.thumbInset),
              decoration: BoxDecoration(
                color: _trackColor(colors),
                borderRadius: radius,
                border: _focused ? Border.all(color: colors.accent) : null,
              ),
              child: AnimatedAlign(
                duration: switches.transitionDuration,
                curve: Curves.easeOut,
                alignment: widget.value
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  width: switches.thumbSize,
                  height: switches.thumbSize,
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
