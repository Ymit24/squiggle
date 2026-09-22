import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

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
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final button = TextButton(
      onPressed: onPressed,
      autofocus: autofocus,
      style: ButtonStyle(
        animationDuration: _animationDuration,
        elevation: const WidgetStatePropertyAll(0),
        shadowColor: const WidgetStatePropertyAll(Colors.transparent),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        splashFactory: NoSplash.splashFactory,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: WidgetStatePropertyAll(
          Size(_isIconOnly ? spacing.buttonHeight : 0, spacing.buttonHeight),
        ),
        padding: WidgetStatePropertyAll(
          _isIconOnly
              ? EdgeInsets.zero
              : EdgeInsets.symmetric(
                  horizontal: spacing.buttonHorizontalPadding,
                ),
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => _foregroundColor(theme, states),
        ),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => _backgroundColor(theme, states),
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => _borderSide(theme, states),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(theme.radii.button),
          ),
        ),
        textStyle: WidgetStatePropertyAll(
          theme.typography.buttonText(emphasized: _emphasized),
        ),
        iconSize: WidgetStatePropertyAll(spacing.buttonIconSize),
      ),
      child: _content(spacing.buttonContentGap),
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

  Color _foregroundColor(SquiggleTheme theme, Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return theme.colors.subtext0.withValues(
        alpha: _disabledForegroundOpacity,
      );
    }
    if (variant == SquiggleButtonVariant.primary) return theme.colors.base;
    if (variant == SquiggleButtonVariant.danger) return theme.colors.onDanger;
    if (variant == SquiggleButtonVariant.ghost && !_isHighlighted(states)) {
      return theme.colors.subtext0;
    }
    return theme.colors.text;
  }

  Color _backgroundColor(SquiggleTheme theme, Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) {
      return variant == SquiggleButtonVariant.ghost
          ? Colors.transparent
          : theme.colors.surface0;
    }
    if (isActive) return theme.colors.surface1;

    return switch (variant) {
      SquiggleButtonVariant.primary =>
        _isHighlighted(states)
            ? theme.colors.text.withValues(alpha: _highlightedBackgroundOpacity)
            : theme.colors.text,
      SquiggleButtonVariant.secondary =>
        _isHighlighted(states) ? theme.colors.surface1 : theme.colors.surface0,
      SquiggleButtonVariant.ghost =>
        _isHighlighted(states) ? theme.colors.surface0 : Colors.transparent,
      SquiggleButtonVariant.danger =>
        _isHighlighted(states)
            ? theme.colors.danger.withValues(
                alpha: _highlightedBackgroundOpacity,
              )
            : theme.colors.danger,
    };
  }

  BorderSide? _borderSide(SquiggleTheme theme, Set<WidgetState> states) {
    final isEnabled = !states.contains(WidgetState.disabled);
    if ((isActive || states.contains(WidgetState.focused)) && isEnabled) {
      return BorderSide(
        color: theme.colors.accent.withValues(alpha: _activeBorderOpacity),
      );
    }
    if (variant == SquiggleButtonVariant.secondary) {
      final color = isEnabled
          ? theme.colors.surface1
          : theme.colors.surface1.withValues(alpha: _disabledBorderOpacity);
      return BorderSide(color: color);
    }
    return null;
  }

  bool _isHighlighted(Set<WidgetState> states) {
    return states.contains(WidgetState.hovered) ||
        states.contains(WidgetState.focused) ||
        states.contains(WidgetState.pressed);
  }
}
