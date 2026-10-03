import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class Button extends StatefulWidget {
  const Button({
    super.key,
    this.iconAsset,
    this.icon,
    this.label,
    this.hotkey,
    required this.isActive,
    required this.onPressed,
  }) : assert(iconAsset != null || icon != null || label != null);

  final String? iconAsset;
  final IconData? icon;
  final String? label;
  final String? hotkey;
  final bool isActive;
  final VoidCallback? onPressed;

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final colors = theme.colors;
    final isEnabled = widget.onPressed != null;
    final Color foregroundColor;
    if (!isEnabled) {
      foregroundColor = colors.surface1;
    } else if (widget.isActive) {
      foregroundColor = colors.text;
    } else {
      foregroundColor = colors.subtext0;
    }

    Widget buttonContent;
    if (widget.iconAsset != null) {
      buttonContent = SvgPicture.asset(
        widget.iconAsset!,
        width: spacing.toolbarIconSize,
        height: spacing.toolbarIconSize,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(foregroundColor, BlendMode.srcIn),
      );
    } else if (widget.icon != null) {
      buttonContent = Icon(
        widget.icon,
        size: spacing.toolbarIconSize,
        color: foregroundColor,
      );
    } else {
      buttonContent = Text(
        widget.label!,
        style: theme.typography.buttonLabel(isActive: widget.isActive),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = isEnabled),
      onExit: (_) => setState(() => _hovering = false),
      cursor: isEnabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: spacing.toolbarButtonSize,
          height: spacing.toolbarButtonSize,
          child: DecoratedBox(
            decoration: theme.decorations.toolbarButton(
              isActive: widget.isActive,
              isHovering: _hovering,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(child: buttonContent),
                if (widget.hotkey != null)
                  Positioned(
                    right: 3,
                    bottom: 2,
                    child: Text(widget.hotkey!, style: theme.typography.hotkey),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
