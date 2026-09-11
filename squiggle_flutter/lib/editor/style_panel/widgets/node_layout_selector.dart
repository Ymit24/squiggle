import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_swatch.dart';
import 'package:squiggle_flutter/models/node_layout.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class NodeAlignSelector extends StatelessWidget {
  const NodeAlignSelector({super.key, required this.onAlign});

  final ValueChanged<NodeAlignment> onAlign;

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
              NodeAlignment.left,
              NodeAlignment.centerHorizontal,
              NodeAlignment.right,
            ])
              _LayoutSwatch(
                icon: switch (alignment) {
                  NodeAlignment.left => Icons.align_horizontal_left,
                  NodeAlignment.centerHorizontal =>
                    Icons.align_horizontal_center,
                  NodeAlignment.right => Icons.align_horizontal_right,
                  _ => Icons.align_horizontal_left,
                },
                tooltip: switch (alignment) {
                  NodeAlignment.left => 'Align left',
                  NodeAlignment.centerHorizontal => 'Align center horizontally',
                  NodeAlignment.right => 'Align right',
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
              NodeAlignment.top,
              NodeAlignment.centerVertical,
              NodeAlignment.bottom,
            ])
              _LayoutSwatch(
                icon: switch (alignment) {
                  NodeAlignment.top => Icons.align_vertical_top,
                  NodeAlignment.centerVertical => Icons.align_vertical_center,
                  NodeAlignment.bottom => Icons.align_vertical_bottom,
                  _ => Icons.align_vertical_top,
                },
                tooltip: switch (alignment) {
                  NodeAlignment.top => 'Align top',
                  NodeAlignment.centerVertical => 'Align center vertically',
                  NodeAlignment.bottom => 'Align bottom',
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

class NodeDistributeSelector extends StatelessWidget {
  const NodeDistributeSelector({super.key, required this.onDistribute});

  final ValueChanged<NodeDistribution> onDistribute;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing.swatchGap,
      children: [
        for (final distribution in NodeDistribution.values)
          _LayoutSwatch(
            icon: switch (distribution) {
              NodeDistribution.horizontal => Icons.horizontal_distribute,
              NodeDistribution.vertical => Icons.vertical_distribute,
            },
            tooltip: switch (distribution) {
              NodeDistribution.horizontal => 'Distribute horizontally',
              NodeDistribution.vertical => 'Distribute vertically',
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
