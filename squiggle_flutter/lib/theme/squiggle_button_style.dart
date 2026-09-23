import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_color_scheme.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// Visual treatment of a Squiggle button.
enum SquiggleButtonVariant {
  /// Light filled button with a bold label. The default.
  primary,

  /// Dark bordered button with a semibold label.
  secondary,

  /// Filled danger-colored button for destructive actions.
  danger,

  /// Borderless button for quiet actions such as Cancel.
  ghost,
}

typedef _VariantStyle = ({
  Color background,
  Color hoverBackground,
  Color pressedBackground,
  Color foreground,
  BorderSide? side,
  FontWeight weight,
});

_VariantStyle _resolve(
  SquiggleButtonVariant variant,
  SquiggleColorScheme colors,
) => switch (variant) {
  SquiggleButtonVariant.primary => (
    background: colors.text,
    hoverBackground: Color.lerp(colors.text, colors.base, 0.12)!,
    pressedBackground: colors.subtext0,
    foreground: colors.base,
    side: null,
    weight: FontWeight.w700,
  ),
  SquiggleButtonVariant.secondary => (
    background: colors.surface0,
    hoverBackground: colors.surface1,
    pressedBackground: colors.mantle,
    foreground: colors.text,
    side: BorderSide(color: colors.surface1),
    weight: FontWeight.w600,
  ),
  SquiggleButtonVariant.danger => (
    background: colors.onDanger,
    hoverBackground: Color.lerp(colors.onDanger, colors.base, 0.12)!,
    pressedBackground: Color.lerp(colors.onDanger, colors.base, 0.2)!,
    foreground: Colors.white,
    side: null,
    weight: FontWeight.w700,
  ),
  SquiggleButtonVariant.ghost => (
    background: Colors.transparent,
    hoverBackground: colors.surface0,
    pressedBackground: colors.surface1,
    foreground: colors.subtext0,
    side: null,
    weight: FontWeight.w600,
  ),
};

extension SquiggleButtonStyle on SquiggleTheme {
  ButtonStyle buttonStyle({
    SquiggleButtonVariant variant = SquiggleButtonVariant.primary,
    bool compact = false,
  }) {
    final s = _resolve(variant, colors);
    final isGhost = variant == SquiggleButtonVariant.ghost;
    return FilledButton.styleFrom(
      splashFactory: NoSplash.splashFactory,
      minimumSize: Size(0, spacing.buttonHeight),
      fixedSize: compact ? Size.square(spacing.buttonHeight) : null,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: compact
          ? EdgeInsets.zero
          : EdgeInsets.symmetric(horizontal: spacing.buttonHorizontalPadding),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radii.button),
      ),
      textStyle: typography.actionButtonLabel.copyWith(fontWeight: s.weight),
      visualDensity: VisualDensity.standard,
    ).copyWith(
      // Every variant owns its interaction colors; Material adds no overlay.
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return isGhost ? Colors.transparent : colors.surface0;
        }
        if (states.contains(WidgetState.pressed)) {
          return s.pressedBackground;
        }
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return s.hoverBackground;
        }
        return s.background;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return colors.subtext0.withValues(alpha: 0.5);
        }
        return s.foreground;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused) &&
            !states.contains(WidgetState.disabled)) {
          return BorderSide(color: colors.accent);
        }
        return s.side;
      }),
    );
  }
}
