import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

enum SquiggleIconTileTone { neutral, danger, accent }

class SquiggleIconTile extends StatelessWidget {
  const SquiggleIconTile({
    super.key,
    required this.icon,
    this.size = 44,
    this.iconSize = 20,
    this.tone = SquiggleIconTileTone.neutral,
    this.radius,
  });

  final IconData icon;
  final double size;
  final double iconSize;
  final SquiggleIconTileTone tone;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final (background, foreground, border) = switch (tone) {
      SquiggleIconTileTone.neutral => (
        theme.colors.surface0,
        theme.colors.subtext0,
        theme.colors.surface1,
      ),
      SquiggleIconTileTone.danger => (
        theme.colors.danger.withValues(alpha: 0.12),
        theme.colors.danger,
        Colors.transparent,
      ),
      SquiggleIconTileTone.accent => (
        theme.colors.surface0,
        theme.colors.text,
        theme.colors.surface1,
      ),
    };
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(radius ?? theme.radii.control),
        border: Border.all(color: border),
      ),
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }
}
