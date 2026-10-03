import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/alignment_swatch.dart';
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
          AlignmentSwatch(
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
