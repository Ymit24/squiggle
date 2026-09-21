import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_pressable.dart';

class Button extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final colors = theme.colors;
    final isEnabled = onPressed != null;
    final foregroundColor = !isEnabled
        ? colors.surface1
        : isActive
        ? colors.text
        : colors.subtext0;

    return SquigglePressable(
      onPressed: onPressed,
      builder: (context, state) => SizedBox(
        width: spacing.toolbarButtonSize,
        height: spacing.toolbarButtonSize,
        child: DecoratedBox(
          decoration: theme.decorations.toolbarButton(
            isActive: isActive,
            isHovering: state.isHighlighted,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: iconAsset != null
                    ? SvgPicture.asset(
                        iconAsset!,
                        width: spacing.toolbarIconSize,
                        height: spacing.toolbarIconSize,
                        fit: BoxFit.contain,
                        colorFilter: ColorFilter.mode(
                          foregroundColor,
                          BlendMode.srcIn,
                        ),
                      )
                    : icon != null
                    ? Icon(
                        icon,
                        size: spacing.toolbarIconSize,
                        color: foregroundColor,
                      )
                    : Text(
                        label!,
                        style: theme.typography.buttonLabel(isActive: isActive),
                      ),
              ),
              if (hotkey != null)
                Positioned(
                  right: 3,
                  bottom: 2,
                  child: Text(hotkey!, style: theme.typography.hotkey),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
