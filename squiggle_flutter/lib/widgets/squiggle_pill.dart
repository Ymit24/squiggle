import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class SquigglePill extends StatelessWidget {
  const SquigglePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final style = (
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
    );
    final text = Text(label, style: style.textStyle);

    return Container(
      padding: style.padding,
      decoration: BoxDecoration(
        color: style.color,
        borderRadius: BorderRadius.circular(999),
        border: style.border,
        boxShadow: style.shadow,
      ),
      child: text,
    );
  }
}
