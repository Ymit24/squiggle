import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/layout_swatch.dart';
import 'package:squiggle_flutter/models/node_layout.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

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
          LayoutSwatch(
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
