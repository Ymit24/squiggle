import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class SquigglePill extends StatelessWidget {
  const SquigglePill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colors.accent.withValues(alpha: 0.5)),
        boxShadow: null,
      ),
      child: Text(
        label,
        style: theme.typography.hotkey.copyWith(
          color: theme.colors.text,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
