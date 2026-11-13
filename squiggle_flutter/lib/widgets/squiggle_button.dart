import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_button_style.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_tooltip.dart';

export 'package:squiggle_flutter/theme/squiggle_button_style.dart'
    show SquiggleButtonVariant;

/// Standard Squiggle button.
///
/// Call sites pass content; styling comes from the Squiggle theme:
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
    this.shortcuts = const [],
  }) : assert(!compact || icon != null, 'compact requires an icon');

  /// Null disables the button.
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;
  final SquiggleButtonVariant variant;

  /// Narrow-screen mode: a fixed square showing only the icon, with the
  /// label moved into a hover tooltip.
  final bool compact;

  /// Shortcuts listed in the compact tooltip, in command-style notation.
  final List<String> shortcuts;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final button = FilledButton(
      onPressed: onPressed,
      style: theme.buttonStyle(variant: variant, compact: compact),
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
    if (compact) {
      return SquiggleTooltip(label: label, shortcuts: shortcuts, child: button);
    }
    return button;
  }
}
