import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/style_color_swatch.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class LayoutSwatch extends StatelessWidget {
  const LayoutSwatch({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.squiggleTheme.colors;

    return StyleColorSwatch(
      color: colors.base,
      tooltip: tooltip,
      isActive: false,
      selectable: false,
      onPressed: onPressed,
      overlay: Icon(icon, size: 14, color: colors.subtext0),
    );
  }
}
