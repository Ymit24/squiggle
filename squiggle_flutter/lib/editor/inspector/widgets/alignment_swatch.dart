import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/style_color_swatch.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class AlignmentSwatch extends StatelessWidget {
  const AlignmentSwatch({
    super.key,
    required this.icon,
    required this.isActive,
    required this.onPressed,
    required this.enabled,
  });

  final IconData icon;
  final bool isActive;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.squiggleTheme.colors;

    return StyleColorSwatch(
      color: colors.base,
      isActive: isActive,
      enabled: enabled,
      onPressed: onPressed,
      overlay: Icon(
        icon,
        size: 14,
        color: isActive ? colors.text : colors.subtext0,
      ),
    );
  }
}
