import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/alignment_swatch.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

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
          AlignmentSwatch(
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
