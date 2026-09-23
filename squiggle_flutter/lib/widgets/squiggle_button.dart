import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_color_scheme.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// Visual treatment of a [SquiggleButton].
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

/// Per-variant styling, resolved once per build by [_resolve].
/// Adding a variant means adding one switch arm; the switch is exhaustive,
/// so the compiler won't let you forget a branch.
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
    hoverBackground: colors.accent,
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
    hoverBackground: colors.danger,
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

/// Standard Squiggle button.
///
/// All styling lives here; call sites just pass content:
///
/// ```dart
/// SquiggleButton(
///   onPressed: onCreate,
///   icon: Icons.add_rounded,
///   label: 'New canvas',
/// )
/// ```
class SquiggleButton extends StatelessWidget {
  const SquiggleButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
    this.variant = SquiggleButtonVariant.primary,
    this.compact = false,
  }) : assert(!compact || icon != null, 'compact requires an icon');

  /// Null disables the button.
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final SquiggleButtonVariant variant;

  /// Narrow-screen mode: a fixed square showing only the icon, with the
  /// label moved into a hover tooltip.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final s = _resolve(variant, theme.colors);
    final spacing = theme.spacing;
    final isGhost = variant == SquiggleButtonVariant.ghost;
    final button = FilledButton(
      onPressed: onPressed,
      style:
          FilledButton.styleFrom(
            splashFactory: NoSplash.splashFactory,
            minimumSize: Size(0, spacing.buttonHeight),
            fixedSize: compact ? Size.square(spacing.buttonHeight) : null,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            padding: compact
                ? EdgeInsets.zero
                : EdgeInsets.symmetric(
                    horizontal: spacing.buttonHorizontalPadding,
                  ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(theme.radii.button),
            ),
            textStyle: theme.typography.actionButtonLabel.copyWith(
              fontWeight: s.weight,
            ),
            visualDensity: VisualDensity.standard,
          ).copyWith(
            // Every variant owns its interaction colors; Material adds no overlay.
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return isGhost ? Colors.transparent : theme.colors.surface0;
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
                return theme.colors.subtext0.withValues(alpha: 0.5);
              }
              return s.foreground;
            }),
            side: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.focused) &&
                  !states.contains(WidgetState.disabled)) {
                return BorderSide(color: theme.colors.accent);
              }
              return s.side;
            }),
          ),
      child: compact
          ? Icon(icon, size: spacing.buttonIconSize)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: spacing.buttonIconSize),
                  SizedBox(width: spacing.buttonIconGap),
                ],
                Text(label),
              ],
            ),
    );
    if (compact) return Tooltip(message: label, child: button);
    return button;
  }
}
