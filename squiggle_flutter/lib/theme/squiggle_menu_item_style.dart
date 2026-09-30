import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

extension SquiggleMenuItemStyle on SquiggleTheme {
  ButtonStyle menuItemStyle() =>
      TextButton.styleFrom(
        foregroundColor: colors.text,
        disabledForegroundColor: colors.subtext0.withValues(alpha: 0.5),
        textStyle: typography.menuItemLabel,
        iconSize: spacing.buttonIconSize,
        minimumSize: Size(0, spacing.menuItemHeight),
        padding: EdgeInsets.symmetric(
          horizontal: spacing.menuItemHorizontalPadding,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radii.button),
        ),
        splashFactory: NoSplash.splashFactory,
      ).copyWith(
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return Colors.transparent;
          if (states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed)) {
            return colors.surface0;
          }
          return Colors.transparent;
        }),
      );
}
