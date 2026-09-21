import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_pressable.dart';

enum SquiggleButtonVariant { primary, secondary, ghost, danger }

enum SquiggleButtonSize { compact, regular }

class SquiggleButton extends StatelessWidget {
  const SquiggleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.variant = SquiggleButtonVariant.secondary,
    this.size = SquiggleButtonSize.regular,
    this.isSelected = false,
  }) : icon = null,
       tooltip = null;

  const SquiggleButton.icon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = SquiggleButtonVariant.secondary,
    this.size = SquiggleButtonSize.regular,
    this.isSelected = false,
  }) : assert(tooltip != ''),
       label = null,
       leading = null,
       trailing = null;

  final String? label;
  final Widget? icon;
  final Widget? leading;
  final Widget? trailing;
  final String? tooltip;
  final VoidCallback? onPressed;
  final SquiggleButtonVariant variant;
  final SquiggleButtonSize size;
  final bool isSelected;

  bool get _isIconOnly => icon != null;

  @override
  Widget build(BuildContext context) {
    final button = SquigglePressable(
      onPressed: onPressed,
      builder: (context, state) {
        final theme = context.squiggleTheme;
        final height = switch (size) {
          SquiggleButtonSize.compact => 28.0,
          SquiggleButtonSize.regular => 38.0,
        };
        final foreground = _foregroundColor(theme, state);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          constraints: BoxConstraints(
            minWidth: _isIconOnly ? height : 0,
            minHeight: height,
          ),
          padding: _isIconOnly
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(
                  horizontal: size == SquiggleButtonSize.compact ? 12 : 14,
                ),
          decoration: BoxDecoration(
            color: _backgroundColor(theme, state),
            border: _border(theme, state),
            borderRadius: BorderRadius.circular(theme.radii.button),
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              color: foreground,
              size: size == SquiggleButtonSize.compact ? 16 : 18,
            ),
            child: DefaultTextStyle(
              style: theme.typography.inputText.copyWith(
                color: foreground,
                fontSize: size == SquiggleButtonSize.compact ? 13 : 13.5,
                fontWeight:
                    variant == SquiggleButtonVariant.primary ||
                        variant == SquiggleButtonVariant.danger
                    ? FontWeight.w700
                    : FontWeight.w600,
              ),
              child: _content(),
            ),
          ),
        );
      },
    );

    final tooltip = this.tooltip;
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Widget _content() {
    final icon = this.icon;
    if (icon != null) {
      return Center(widthFactor: 1, heightFactor: 1, child: icon);
    }

    final gap = SizedBox(width: size == SquiggleButtonSize.compact ? 6 : 7);
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, gap],
        Text(label!),
        if (trailing != null) ...[gap, trailing!],
      ],
    );
  }

  Color _foregroundColor(SquiggleTheme theme, SquigglePressableState state) {
    if (!state.isEnabled) {
      return theme.colors.subtext0.withValues(alpha: 0.45);
    }
    if (variant == SquiggleButtonVariant.primary) return theme.colors.base;
    if (variant == SquiggleButtonVariant.danger) return Colors.white;
    if (variant == SquiggleButtonVariant.ghost && !state.isHighlighted) {
      return theme.colors.subtext0;
    }
    return theme.colors.text;
  }

  Color _backgroundColor(SquiggleTheme theme, SquigglePressableState state) {
    if (!state.isEnabled) {
      return variant == SquiggleButtonVariant.ghost
          ? Colors.transparent
          : theme.colors.surface0;
    }
    if (isSelected) return theme.colors.surface1;

    return switch (variant) {
      SquiggleButtonVariant.primary =>
        state.isHighlighted
            ? theme.colors.text.withValues(alpha: 0.9)
            : theme.colors.text,
      SquiggleButtonVariant.secondary =>
        state.isHighlighted ? theme.colors.surface1 : theme.colors.surface0,
      SquiggleButtonVariant.ghost =>
        state.isHighlighted ? theme.colors.surface0 : Colors.transparent,
      SquiggleButtonVariant.danger => const Color(
        0xFFD95F5F,
      ).withValues(alpha: state.isHighlighted ? 0.9 : 1),
    };
  }

  Border? _border(SquiggleTheme theme, SquigglePressableState state) {
    if (isSelected && state.isEnabled) {
      return Border.all(color: theme.colors.accent.withValues(alpha: 0.5));
    }
    if (variant == SquiggleButtonVariant.secondary) {
      return Border.all(
        color: theme.colors.surface1.withValues(
          alpha: state.isEnabled ? 1 : 0.5,
        ),
      );
    }
    return null;
  }
}
