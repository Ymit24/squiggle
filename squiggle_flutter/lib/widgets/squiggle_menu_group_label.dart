import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';

class SquiggleMenuGroupLabel extends StatelessWidget {
  const SquiggleMenuGroupLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: theme.spacing.menuItemHorizontalPadding,
        vertical: theme.spacing.menuPadding / 2,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: theme.typography.menuItemLabel.copyWith(
            color: theme.colors.subtext0,
          ),
        ),
      ),
    );
  }
}
