import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';

class SquiggleMenuDivider extends StatelessWidget {
  const SquiggleMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.menuItemHorizontalPadding,
      ),
      child: Divider(
        height: theme.spacing.menuDividerHeight,
        thickness: 1,
        color: theme.colors.surface1,
      ),
    );
  }
}
