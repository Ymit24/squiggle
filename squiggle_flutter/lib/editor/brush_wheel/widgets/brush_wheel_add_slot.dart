import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/brush_wheel/brush_wheel_geometry.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// The wheel's trailing "new brush" slot.
class BrushWheelAddSlot extends StatelessWidget {
  const BrushWheelAddSlot({super.key, required this.hovered});

  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;

    return AnimatedScale(
      scale: hovered ? 1.12 : 1,
      duration: const Duration(milliseconds: 70),
      child: Container(
        width: BrushWheelGeometry.slotSize,
        height: BrushWheelGeometry.slotSize,
        decoration: BoxDecoration(
          color: hovered ? colors.surface0 : colors.base,
          border: Border.all(color: hovered ? colors.text : colors.surface1),
          borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
        ),
        child: Icon(
          Icons.add,
          size: 22,
          color: hovered ? colors.text : colors.subtext0,
        ),
      ),
    );
  }
}
