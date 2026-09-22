import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_pressable.dart';

const _animationDuration = Duration(milliseconds: 140);
const _disabledForegroundOpacity = 0.45;
const _highlightedBackgroundOpacity = 0.9;
const _activeBorderOpacity = 0.5;
const _disabledBorderOpacity = 0.5;

enum SquiggleButtonVariant { primary, secondary, ghost, danger }

class SquiggleButton extends StatelessWidget {
  const SquiggleButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.leading,
    this.trailing,
    this.variant = SquiggleButtonVariant.secondary,
    this.isActive = false,
    this.autofocus = false,
  }) : assert(label != ''),
       icon = null,
       tooltip = null;

  const SquiggleButton.icon({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.variant = SquiggleButtonVariant.secondary,
    this.isActive = false,
    this.autofocus = false,
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
  final bool isActive;
  final bool autofocus;

  bool get _isIconOnly => icon != null;
  bool get _emphasized =>
      variant == SquiggleButtonVariant.primary ||
      variant == SquiggleButtonVariant.danger;

  @override
  Widget build(BuildContext context) {
    final button = SquigglePressable(
      onPressed: onPressed,
      autofocus: autofocus,
      builder: (context, state) {
        final theme = context.squiggleTheme;
        final spacing = theme.spacing;
        final foreground = _foregroundColor(theme, state);

        return AnimatedContainer(
          duration: _animationDuration,
          constraints: BoxConstraints(
            minWidth: _isIconOnly ? spacing.buttonHeight : 0,
            minHeight: spacing.buttonHeight,
          ),
          padding: _isIconOnly
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(
                  horizontal: spacing.buttonHorizontalPadding,
                ),
          decoration: BoxDecoration(
            color: _backgroundColor(theme, state),
            border: _border(theme, state),
            borderRadius: BorderRadius.circular(theme.radii.button),
          ),
          child: IconTheme.merge(
            data: IconThemeData(
              color: foreground,
              size: spacing.buttonIconSize,
            ),
            child: DefaultTextStyle(
              style: theme.typography
                  .buttonText(emphasized: _emphasized)
                  .copyWith(color: foreground),
              child: _content(spacing.buttonContentGap),
            ),
          ),
        );
      },
    );

    final tooltip = this.tooltip;
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }

  Widget _content(double gapWidth) {
    final icon = this.icon;
    if (icon != null) {
      return Center(widthFactor: 1, heightFactor: 1, child: icon);
    }

    final gap = SizedBox(width: gapWidth);
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
      return theme.colors.subtext0.withValues(
        alpha: _disabledForegroundOpacity,
      );
    }
    if (variant == SquiggleButtonVariant.primary) return theme.colors.base;
    if (variant == SquiggleButtonVariant.danger) return theme.colors.onDanger;
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
    if (isActive) return theme.colors.surface1;

    return switch (variant) {
      SquiggleButtonVariant.primary =>
        state.isHighlighted
            ? theme.colors.text.withValues(alpha: _highlightedBackgroundOpacity)
            : theme.colors.text,
      SquiggleButtonVariant.secondary =>
        state.isHighlighted ? theme.colors.surface1 : theme.colors.surface0,
      SquiggleButtonVariant.ghost =>
        state.isHighlighted ? theme.colors.surface0 : Colors.transparent,
      SquiggleButtonVariant.danger =>
        state.isHighlighted
            ? theme.colors.danger.withValues(
                alpha: _highlightedBackgroundOpacity,
              )
            : theme.colors.danger,
    };
  }

  Border? _border(SquiggleTheme theme, SquigglePressableState state) {
    if ((isActive || state.isFocused) && state.isEnabled) {
      return Border.all(
        color: theme.colors.accent.withValues(alpha: _activeBorderOpacity),
      );
    }
    if (variant == SquiggleButtonVariant.secondary) {
      final color = state.isEnabled
          ? theme.colors.surface1
          : theme.colors.surface1.withValues(alpha: _disabledBorderOpacity);
      return Border.all(color: color);
    }
    return null;
  }
}
