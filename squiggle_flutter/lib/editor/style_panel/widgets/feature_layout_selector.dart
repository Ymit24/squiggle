import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_swatch.dart';
import 'package:squiggle_flutter/models/feature_layout.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class FeatureAlignSelector extends StatelessWidget {
  const FeatureAlignSelector({
    super.key,
    required this.onAlign,
  });

  final ValueChanged<FeatureAlignment> onAlign;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.spacing.swatchGap,
          children: [
            for (final alignment in [
              FeatureAlignment.left,
              FeatureAlignment.centerHorizontal,
              FeatureAlignment.right,
            ])
              _LayoutSwatch(
                icon: switch (alignment) {
                  FeatureAlignment.left => Icons.align_horizontal_left,
                  FeatureAlignment.centerHorizontal =>
                    Icons.align_horizontal_center,
                  FeatureAlignment.right => Icons.align_horizontal_right,
                  _ => Icons.align_horizontal_left,
                },
                tooltip: switch (alignment) {
                  FeatureAlignment.left => 'Align left',
                  FeatureAlignment.centerHorizontal =>
                    'Align center horizontally',
                  FeatureAlignment.right => 'Align right',
                  _ => '',
                },
                onPressed: () => onAlign(alignment),
              ),
          ],
        ),
        SizedBox(height: theme.spacing.swatchGap),
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: theme.spacing.swatchGap,
          children: [
            for (final alignment in [
              FeatureAlignment.top,
              FeatureAlignment.centerVertical,
              FeatureAlignment.bottom,
            ])
              _LayoutSwatch(
                icon: switch (alignment) {
                  FeatureAlignment.top => Icons.align_vertical_top,
                  FeatureAlignment.centerVertical =>
                    Icons.align_vertical_center,
                  FeatureAlignment.bottom => Icons.align_vertical_bottom,
                  _ => Icons.align_vertical_top,
                },
                tooltip: switch (alignment) {
                  FeatureAlignment.top => 'Align top',
                  FeatureAlignment.centerVertical => 'Align center vertically',
                  FeatureAlignment.bottom => 'Align bottom',
                  _ => '',
                },
                onPressed: () => onAlign(alignment),
              ),
          ],
        ),
      ],
    );
  }
}

class FeatureDistributeSelector extends StatelessWidget {
  const FeatureDistributeSelector({
    super.key,
    required this.onDistribute,
  });

  final ValueChanged<FeatureDistribution> onDistribute;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing.swatchGap,
      children: [
        for (final distribution in FeatureDistribution.values)
          _LayoutSwatch(
            icon: switch (distribution) {
              FeatureDistribution.horizontal => Icons.horizontal_distribute,
              FeatureDistribution.vertical => Icons.vertical_distribute,
            },
            tooltip: switch (distribution) {
              FeatureDistribution.horizontal => 'Distribute horizontally',
              FeatureDistribution.vertical => 'Distribute vertically',
            },
            onPressed: () => onDistribute(distribution),
          ),
      ],
    );
  }
}

class _LayoutSwatch extends StatelessWidget {
  const _LayoutSwatch({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;

    return Tooltip(
      message: tooltip,
      child: StyleColorSwatch(
        color: colors.base,
        isActive: false,
        onPressed: onPressed,
        overlay: Icon(icon, size: 14, color: colors.subtext0),
      ),
    );
  }
}
