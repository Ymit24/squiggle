import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

import 'metrics.dart';

class Divider extends StatelessWidget {
  const Divider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: dividerHeight,
      margin: const EdgeInsets.symmetric(horizontal: gap),
      color: SquiggleColors.surface1,
    );
  }
}
