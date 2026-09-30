import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// A compact menu action. A null [onPressed] disables the item.
class SquiggleMenuItem extends StatelessWidget {
  const SquiggleMenuItem({
    super.key,
    required this.label,
    required this.icon,
    required this.shortcut,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final String shortcut;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return TextButton(
      onPressed: onPressed,
      style: theme.menuItemStyle(),
      child: Row(
        children: [
          Icon(icon),
          SizedBox(width: theme.spacing.menuIconGap),
          Expanded(child: Text(label)),
          SizedBox(width: theme.spacing.menuShortcutGap),
          Text(
            shortcut,
            style: TextStyle(
              color: onPressed == null ? null : theme.colors.subtext0,
            ),
          ),
        ],
      ),
    );
  }
}
