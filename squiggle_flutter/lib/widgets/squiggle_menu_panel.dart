import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';

class SquiggleMenuPanel extends StatelessWidget {
  const SquiggleMenuPanel({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final availableSize = MediaQuery.sizeOf(context);
    final maxWidth = math.max(
      0.0,
      availableSize.width - theme.spacing.panelPadding * 2,
    );
    return IntrinsicWidth(
      child: Container(
        constraints: BoxConstraints(
          minWidth: math.min(theme.spacing.menuWidth, maxWidth),
          maxWidth: maxWidth,
          maxHeight: math.max(
            0.0,
            availableSize.height - theme.spacing.panelPadding * 2,
          ),
        ),
        decoration: theme.decorations.floatingPanel(),
        padding: EdgeInsets.all(theme.spacing.menuPadding),
        child: Material(
          type: MaterialType.transparency,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
