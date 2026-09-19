import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

enum SquiggleButtonVariant { primary, secondary, danger, ghost }

enum SquiggleButtonSize { regular, compact }

class SquiggleButton extends StatelessWidget {
  const SquiggleButton({
    super.key,
    required this.onPressed,
    this.label,
    this.icon,
    this.variant = SquiggleButtonVariant.primary,
    this.size = SquiggleButtonSize.regular,
    this.tooltip,
  }) : assert(label != null || icon != null);

  final VoidCallback? onPressed;
  final String? label;
  final IconData? icon;
  final SquiggleButtonVariant variant;
  final SquiggleButtonSize size;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final compact = size == SquiggleButtonSize.compact;
    final controlHeight = theme.spacing.controlHeight;
    final child = label == null
        ? Icon(icon, size: 18)
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17),
                const SizedBox(width: 5),
              ],
              Text(label!, style: theme.typography.controlLabel),
            ],
          );
    final sizeStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(
        compact ? Size.square(controlHeight) : Size(0, controlHeight),
      ),
      fixedSize: compact
          ? WidgetStatePropertyAll(Size.square(controlHeight))
          : null,
      padding: WidgetStatePropertyAll(
        compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 11),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    final button = switch (variant) {
      SquiggleButtonVariant.ghost => TextButton(
        onPressed: onPressed,
        style: sizeStyle,
        child: child,
      ),
      SquiggleButtonVariant.primary ||
      SquiggleButtonVariant.secondary ||
      SquiggleButtonVariant.danger => FilledButton(
        onPressed: onPressed,
        style: sizeStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colors.surface0;
            }
            final base = switch (variant) {
              SquiggleButtonVariant.primary => theme.colors.text,
              SquiggleButtonVariant.secondary => theme.colors.surface1,
              SquiggleButtonVariant.danger => theme.colors.dangerStrong,
              SquiggleButtonVariant.ghost => Colors.transparent,
            };
            return states.contains(WidgetState.hovered)
                ? base.withValues(alpha: 0.9)
                : base;
          }),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.disabled)
                ? theme.colors.subtext0.withValues(alpha: 0.5)
                : variant == SquiggleButtonVariant.danger
                ? theme.colors.onDanger
                : variant == SquiggleButtonVariant.secondary
                ? theme.colors.text
                : theme.colors.base,
          ),
        ),
        child: child,
      ),
    };

    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}
