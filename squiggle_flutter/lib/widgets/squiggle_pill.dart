import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

enum _PillVariant { count, current, action }

typedef _PillStyle = ({
  EdgeInsets padding,
  Color color,
  BoxBorder? border,
  List<BoxShadow>? shadow,
  TextStyle textStyle,
});

class SquigglePill extends StatelessWidget {
  const SquigglePill.count({super.key, required this.label})
    : _variant = _PillVariant.count,
      icon = null;

  const SquigglePill.current({super.key, required this.label})
    : _variant = _PillVariant.current,
      icon = null;

  const SquigglePill.action({
    super.key,
    required this.label,
    required this.icon,
  }) : _variant = _PillVariant.action;

  final String label;
  final IconData? icon;
  final _PillVariant _variant;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final style = _resolveStyle(theme);
    final text = Text(label, style: style.textStyle);
    final leading = switch (_variant) {
      _PillVariant.count => null,
      _PillVariant.current => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: theme.colors.accent,
          shape: BoxShape.circle,
        ),
      ),
      _PillVariant.action => Icon(icon, size: 14, color: Colors.black87),
    };

    return Container(
      padding: style.padding,
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(999),
        border: style.border,
        boxShadow: style.shadow,
      ),
      child: leading == null
          ? text
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [leading, const SizedBox(width: 6), text],
            ),
    );
  }

  _PillStyle _resolveStyle(SquiggleTheme theme) => switch (_variant) {
    _PillVariant.count => (
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: theme.colors.surface0,
      border: Border.all(color: theme.colors.surface1),
      shadow: null,
      textStyle: theme.typography.hotkey.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    ),
    _PillVariant.current => (
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      color: Colors.black.withValues(alpha: 0.55),
      border: Border.all(color: theme.colors.accent.withValues(alpha: 0.5)),
      shadow: null,
      textStyle: theme.typography.hotkey.copyWith(
        color: theme.colors.text,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
    _PillVariant.action => (
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      color: theme.colors.text,
      border: null,
      shadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.4),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
      textStyle: const TextStyle(
        color: Colors.black87,
        fontSize: 12.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
    ),
  };
}
