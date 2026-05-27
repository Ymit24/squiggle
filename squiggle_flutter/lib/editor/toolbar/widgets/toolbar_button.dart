import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

import 'toolbar_metrics.dart';

class ToolbarButton extends StatefulWidget {
  const ToolbarButton({
    super.key,
    required this.iconAsset,
    required this.isActive,
    required this.onPressed,
  });

  final String iconAsset;
  final bool isActive;
  final VoidCallback onPressed;

  @override
  State<ToolbarButton> createState() => _ToolbarButtonState();
}

class _ToolbarButtonState extends State<ToolbarButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isActive
        ? SquiggleColors.surface1
        : (_hovering ? SquiggleColors.surface0 : null);
    final iconColor = widget.isActive
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
          width: toolButtonSize,
          height: toolButtonSize,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(toolbarButtonRadius),
            ),
            child: Center(
              child: SvgPicture.asset(
                widget.iconAsset,
                width: toolbarIconSize,
                height: toolbarIconSize,
                fit: BoxFit.contain,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
