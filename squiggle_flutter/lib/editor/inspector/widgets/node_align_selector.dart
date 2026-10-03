import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/layout_swatch.dart';
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
        _buildAlignmentRow(theme.spacing.swatchGap, [
          NodeAlignment.left,
          NodeAlignment.centerHorizontal,
          NodeAlignment.right,
        ]),
        SizedBox(height: theme.spacing.swatchGap),
        _buildAlignmentRow(theme.spacing.swatchGap, [
          NodeAlignment.top,
          NodeAlignment.centerVertical,
          NodeAlignment.bottom,
        ]),
      ],
    );
  }

  Widget _buildAlignmentRow(double swatchGap, List<NodeAlignment> alignments) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: swatchGap,
      children: [
        for (final alignment in alignments)
          LayoutSwatch(
            icon: _alignmentIcon(alignment),
            tooltip: _alignmentTooltip(alignment),
            onPressed: () => onAlign(alignment),
          ),
      ],
    );
  }
}

IconData _alignmentIcon(NodeAlignment alignment) => switch (alignment) {
  NodeAlignment.left => Icons.align_horizontal_left,
  NodeAlignment.centerHorizontal => Icons.align_horizontal_center,
  NodeAlignment.right => Icons.align_horizontal_right,
  NodeAlignment.top => Icons.align_vertical_top,
  NodeAlignment.centerVertical => Icons.align_vertical_center,
  NodeAlignment.bottom => Icons.align_vertical_bottom,
};

String _alignmentTooltip(NodeAlignment alignment) => switch (alignment) {
  NodeAlignment.left => 'Align left',
  NodeAlignment.centerHorizontal => 'Align center horizontally',
  NodeAlignment.right => 'Align right',
  NodeAlignment.top => 'Align top',
  NodeAlignment.centerVertical => 'Align center vertically',
  NodeAlignment.bottom => 'Align bottom',
};
