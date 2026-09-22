import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_color_scheme.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// Visual treatment of a [SquiggleButton].
enum SquiggleButtonVariant {
  /// Light filled button with a bold label. The default.
  primary,

  /// Dark bordered button with a semibold label.
  secondary,
}

/// Per-variant styling, resolved once per build by [_resolve].
/// Adding a variant means adding one switch arm; the switch is exhaustive,
/// so the compiler won't let you forget a branch.
typedef _VariantStyle = ({
  Color background,
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
    foreground: colors.base,
    side: null,
    weight: FontWeight.w700,
  ),
  SquiggleButtonVariant.secondary => (
    background: colors.surface0,
    foreground: colors.text,
    side: BorderSide(color: colors.surface1),
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

  /// Null disables the button; disabled colors come free from [FilledButton].
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final SquiggleButtonVariant variant;

  /// Narrow-screen mode: a fixed square showing only the icon, with the
  /// label moved into a hover tooltip.
  final bool compact;

  static const _height = 38.0;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final s = _resolve(variant, theme.colors);
    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: s.background,
        foregroundColor: s.foreground,
        disabledBackgroundColor: theme.colors.surface0,
        disabledForegroundColor: theme.colors.subtext0.withValues(alpha: 0.5),
        side: s.side,
        splashFactory: NoSplash.splashFactory,
        minimumSize: const Size(0, _height),
        fixedSize: compact ? const Size.square(_height) : null,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: compact
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        textStyle: TextStyle(fontSize: 13.5, fontWeight: s.weight),
        visualDensity: VisualDensity.standard,
      ),
      child: compact
          ? Icon(icon, size: 18)
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18),
                  const SizedBox(width: 7),
                ],
                Text(label),
              ],
            ),
    );
    if (compact) return Tooltip(message: label, child: button);
    return button;
  }
}
