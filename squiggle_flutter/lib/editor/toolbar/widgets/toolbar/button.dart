import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:squiggle_flutter/theme/squiggle_color_scheme.dart';
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
    final isEnabled = widget.onPressed != null;
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
                Center(child: _buttonContent(theme)),
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

  Color _foregroundColor(SquiggleColorScheme colors) {
    if (widget.onPressed == null) {
      return colors.surface1;
    }
    if (widget.isActive) {
      return colors.text;
    }
    return colors.subtext0;
  }

  Widget _buttonContent(SquiggleTheme theme) {
    final foregroundColor = _foregroundColor(theme.colors);
    final iconSize = theme.spacing.toolbarIconSize;
    if (widget.iconAsset != null) {
      return SvgPicture.asset(
        widget.iconAsset!,
        width: iconSize,
        height: iconSize,
        fit: BoxFit.contain,
        colorFilter: ColorFilter.mode(foregroundColor, BlendMode.srcIn),
      );
    }
    if (widget.icon != null) {
      return Icon(widget.icon, size: iconSize, color: foregroundColor);
    }
    return Text(
      widget.label!,
      style: theme.typography.buttonLabel(isActive: widget.isActive),
    );
  }
}
