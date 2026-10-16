import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/brush_wheel/brush_wheel_geometry.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// The shared frame of a wheel slot: a tile that grows and highlights while
/// hovered, with an accent border when [active].
class BrushWheelTile extends StatelessWidget {
  const BrushWheelTile({
    super.key,
    required this.hovered,
    this.active = false,
    required this.child,
  });

  final bool hovered;
  final bool active;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;
    final borderColor = switch ((hovered, active)) {
      (true, _) => colors.text,
      (_, true) => colors.accent,
      _ => colors.surface1,
    };

    return AnimatedScale(
      scale: hovered ? BrushWheelGeometry.hoverScale : 1,
      duration: BrushWheelGeometry.hoverDuration,
      child: Container(
        width: BrushWheelGeometry.slotSize,
        height: BrushWheelGeometry.slotSize,
        decoration: BoxDecoration(
          color: hovered ? colors.surface0 : colors.base,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
        ),
        child: child,
      ),
    );
  }
}
