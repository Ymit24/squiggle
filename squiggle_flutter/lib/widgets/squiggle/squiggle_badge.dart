import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class SquiggleBadge extends StatelessWidget {
  const SquiggleBadge({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? theme.colors.surface0,
        borderRadius: BorderRadius.circular(theme.radii.pill),
        border: borderColor == null ? null : Border.all(color: borderColor!),
        boxShadow: boxShadow,
      ),
      child: child,
    );
  }
}
