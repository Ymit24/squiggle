import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';

class SquiggleMenuPanel extends StatelessWidget {
  const SquiggleMenuPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Container(
      width: theme.spacing.menuWidth,
      decoration: theme.decorations.floatingPanel(),
      padding: EdgeInsets.all(theme.spacing.menuPadding),
      child: Material(
        type: MaterialType.transparency,
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}
