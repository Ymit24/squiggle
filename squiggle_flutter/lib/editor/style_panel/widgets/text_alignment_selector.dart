import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_swatch.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class TextHorizontalAlignmentSelector extends StatelessWidget {
  const TextHorizontalAlignmentSelector({
    super.key,
    required this.activeAlignment,
    required this.isMixed,
    required this.onAlignmentSelected,
    this.enabled = true,
  });

  final TextHorizontalAlignment? activeAlignment;
  final bool isMixed;
  final ValueChanged<TextHorizontalAlignment> onAlignmentSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing.swatchGap,
      children: [
        for (final alignment in TextHorizontalAlignment.values)
          _AlignmentSwatch(
            icon: switch (alignment) {
              TextHorizontalAlignment.left => Icons.format_align_left,
              TextHorizontalAlignment.center => Icons.format_align_center,
              TextHorizontalAlignment.right => Icons.format_align_right,
            },
            isActive: !isMixed && activeAlignment == alignment,
            enabled: enabled,
            onPressed: () => onAlignmentSelected(alignment),
          ),
      ],
    );
  }
}

class TextVerticalAlignmentSelector extends StatelessWidget {
  const TextVerticalAlignmentSelector({
    super.key,
    required this.activeAlignment,
    required this.isMixed,
    required this.onAlignmentSelected,
    this.enabled = true,
  });

  final TextVerticalAlignment? activeAlignment;
  final bool isMixed;
  final ValueChanged<TextVerticalAlignment> onAlignmentSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing.swatchGap,
      children: [
        for (final alignment in TextVerticalAlignment.values)
          _AlignmentSwatch(
            icon: switch (alignment) {
              TextVerticalAlignment.top => Icons.vertical_align_top,
              TextVerticalAlignment.center => Icons.vertical_align_center,
              TextVerticalAlignment.bottom => Icons.vertical_align_bottom,
            },
            isActive: !isMixed && activeAlignment == alignment,
            enabled: enabled,
            onPressed: () => onAlignmentSelected(alignment),
          ),
      ],
    );
  }
}

class _AlignmentSwatch extends StatelessWidget {
  const _AlignmentSwatch({
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
    final theme = context.squiggleTheme;
    final colors = theme.colors;

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
