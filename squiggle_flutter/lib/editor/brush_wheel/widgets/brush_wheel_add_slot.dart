import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_wheel_tile.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// The wheel's trailing "new brush" slot.
class BrushWheelAddSlot extends StatelessWidget {
  const BrushWheelAddSlot({super.key, required this.hovered});

  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final colors = context.squiggleTheme.colors;

    return BrushWheelTile(
      hovered: hovered,
      child: Icon(
        Icons.add,
        size: 22,
        color: hovered ? colors.text : colors.subtext0,
      ),
    );
  }
}
