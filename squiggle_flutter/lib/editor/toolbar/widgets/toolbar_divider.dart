import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

import 'toolbar_metrics.dart';

class ToolbarDivider extends StatelessWidget {
  const ToolbarDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: toolbarDividerHeight,
      margin: const EdgeInsets.symmetric(horizontal: toolbarGap),
      color: SquiggleColors.surface1,
    );
  }
}
