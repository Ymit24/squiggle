import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/brush_wheel/brush_wheel_geometry.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_swatch.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/theme.dart';

class BrushWheelSlot extends StatelessWidget {
  const BrushWheelSlot({
    super.key,
    required this.brush,
    required this.number,
    required this.kind,
    required this.active,
    required this.hovered,
    required this.imageRepository,
  });

  final BrushProfile brush;
  final int number;
  final FeatureKind kind;
  final bool active;
  final bool hovered;
  final ImageRepository imageRepository;

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
      scale: hovered ? 1.12 : 1,
      duration: const Duration(milliseconds: 70),
      child: Container(
        width: BrushWheelGeometry.slotSize,
        height: BrushWheelGeometry.slotSize,
        decoration: BoxDecoration(
          color: hovered ? colors.surface0 : colors.base,
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            BrushSwatch(
              brush: brush,
              kind: kind,
              imageRepository: imageRepository,
            ),
            Positioned(
              left: 4,
              top: 4,
              child: Text('$number', style: theme.typography.hotkey),
            ),
            if (active)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
