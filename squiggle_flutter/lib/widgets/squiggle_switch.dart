import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

const _trackWidth = 36.0;
const _trackHeight = 20.0;
const _thumbInset = 3.0;
const _duration = Duration(milliseconds: 150);

/// Compact on/off switch. On mirrors the primary button: a `text` track with
/// a `base` thumb.
class SquiggleSwitch extends StatefulWidget {
  const SquiggleSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  @override
  State<SquiggleSwitch> createState() => _SquiggleSwitchState();
}

class _SquiggleSwitchState extends State<SquiggleSwitch> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onChanged != null;
    return Semantics(
      toggled: widget.value,
      enabled: enabled,
      onTap: enabled ? _toggle : null,
      child: FocusableActionDetector(
        enabled: enabled,
        mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
        onShowFocusHighlight: (focused) => setState(() => _focused = focused),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => _toggle(),
          ),
        },
        child: GestureDetector(
          onTap: enabled ? _toggle : null,
          child: _track(context.squiggleTheme),
        ),
      ),
    );
  }

  void _toggle() => widget.onChanged?.call(!widget.value);

  Widget _track(SquiggleTheme theme) {
    final colors = theme.colors;
    final on = widget.value;
    final radius = BorderRadius.circular(_trackHeight / 2);
    return Opacity(
      opacity: widget.onChanged == null ? 0.5 : 1,
      child: AnimatedContainer(
        duration: _duration,
        width: _trackWidth,
        height: _trackHeight,
        padding: const EdgeInsets.all(_thumbInset),
        decoration: BoxDecoration(
          color: on ? colors.text : colors.surface1,
          borderRadius: radius,
        ),
        foregroundDecoration: _focused
            ? BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: colors.accent),
              )
            : null,
        child: AnimatedAlign(
          duration: _duration,
          curve: Curves.easeOut,
          alignment: on ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: _duration,
            width: _trackHeight - _thumbInset * 2,
            height: _trackHeight - _thumbInset * 2,
            decoration: BoxDecoration(
              color: on ? colors.base : colors.subtext0,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
