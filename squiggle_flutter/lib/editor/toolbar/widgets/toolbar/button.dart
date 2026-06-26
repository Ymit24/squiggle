import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

import 'metrics.dart';

class Button extends StatefulWidget {
  const Button({
    super.key,
    this.iconAsset,
    this.label,
    this.hotkey,
    required this.isActive,
    required this.onPressed,
  }) : assert(iconAsset != null || label != null);

  final String? iconAsset;
  final String? label;
  final String? hotkey;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  State<Button> createState() => _ButtonState();
}

class _ButtonState extends State<Button> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isActive
        ? SquiggleColors.surface1
        : (_hovering ? SquiggleColors.surface0 : null);
    final foregroundColor = widget.isActive
        ? SquiggleColors.text
        : SquiggleColors.subtext0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(buttonRadius),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(
                  child: widget.iconAsset != null
                      ? SvgPicture.asset(
                          widget.iconAsset!,
                          width: iconSize,
                          height: iconSize,
                          fit: BoxFit.contain,
                          colorFilter: ColorFilter.mode(
                            foregroundColor,
                            BlendMode.srcIn,
                          ),
                        )
                      : Text(
                          widget.label!,
                          style: TextStyle(
                            color: foregroundColor,
                            fontSize: iconSize,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                if (widget.hotkey != null)
                  Positioned(
                    right: 3,
                    bottom: 2,
                    child: Text(
                      widget.hotkey!,
                      style: TextStyle(
                        color: SquiggleColors.subtext0,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        height: 1,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
