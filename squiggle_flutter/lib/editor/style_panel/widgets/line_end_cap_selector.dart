import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_swatch.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class LineEndCapSelector extends StatelessWidget {
  const LineEndCapSelector({
    super.key,
    required this.activeEndCap,
    required this.isMixed,
    required this.isStart,
    required this.onEndCapSelected,
  });

  final LineEndCap? activeEndCap;
  final bool isMixed;
  final bool isStart;
  final ValueChanged<LineEndCap> onEndCapSelected;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing.swatchGap,
      children: [
        for (final endCap in LineEndCap.values)
          StyleColorSwatch(
            color: theme.colors.base,
            isActive: !isMixed && activeEndCap == endCap,
            onPressed: () => onEndCapSelected(endCap),
            overlay: Icon(
              switch (endCap) {
                LineEndCap.rounded => Icons.horizontal_rule_rounded,
                LineEndCap.arrow =>
                  isStart
                      ? Icons.arrow_back_rounded
                      : Icons.arrow_forward_rounded,
              },
              size: 16,
              color: !isMixed && activeEndCap == endCap
                  ? theme.colors.text
                  : theme.colors.subtext0,
            ),
          ),
      ],
    );
  }
}
