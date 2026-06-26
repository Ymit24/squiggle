import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class Divider extends StatelessWidget {
  const Divider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;

    return Container(
      width: 1,
      height: spacing.toolbarDividerHeight,
      margin: EdgeInsets.symmetric(horizontal: spacing.toolbarGap),
      color: theme.colors.surface1,
    );
  }
}
