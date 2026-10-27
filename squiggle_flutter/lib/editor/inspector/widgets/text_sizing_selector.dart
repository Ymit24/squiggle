import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/alignment_swatch.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class TextSizingSelector extends StatelessWidget {
  const TextSizingSelector({
    super.key,
    required this.activeSizing,
    required this.isMixed,
    required this.onSizingSelected,
    this.enabled = true,
  });

  final TextSizing? activeSizing;
  final bool isMixed;
  final ValueChanged<TextSizing> onSizingSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing.swatchGap,
      children: [
        for (final sizing in TextSizing.values)
          AlignmentSwatch(
            icon: switch (sizing) {
              TextSizing.auto => Icons.format_size,
              TextSizing.fixedWidth => Icons.wrap_text,
            },
            isActive: !isMixed && activeSizing == sizing,
            enabled: enabled,
            onPressed: () => onSizingSelected(sizing),
          ),
      ],
    );
  }
}
