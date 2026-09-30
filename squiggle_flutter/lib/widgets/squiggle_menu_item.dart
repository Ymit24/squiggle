import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// A compact menu action. A null [onPressed] disables the item.
class SquiggleMenuItem extends StatelessWidget {
  const SquiggleMenuItem({
    super.key,
    required this.label,
    this.icon,
    this.shortcut,
    this.danger = false,
    this.checked = false,
    required this.onPressed,
  });

  final String label;
  final IconData? icon;
  final String? shortcut;
  final bool danger;
  final bool checked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return MenuItemButton(
      requestFocusOnHover: false,
      overflowAxis: Axis.vertical,
      onPressed: onPressed,
      style: theme.menuItemStyle(danger: danger),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon),
            SizedBox(width: theme.spacing.menuIconGap),
          ],
          Expanded(child: Text(label)),
          if (shortcut != null) ...[
            SizedBox(width: theme.spacing.menuShortcutGap),
            Text(
              shortcut!,
              style: TextStyle(
                color: onPressed == null ? null : theme.colors.subtext0,
              ),
            ),
          ],
          if (checked) ...[
            SizedBox(width: theme.spacing.menuShortcutGap),
            Icon(Icons.check_rounded, color: theme.colors.accent),
          ],
        ],
      ),
    );
  }
}
