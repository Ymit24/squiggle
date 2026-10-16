import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_swatch.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_wheel_tile.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/theme.dart';

class BrushWheelSlot extends StatelessWidget {
  const BrushWheelSlot({
    super.key,
    required this.brush,
    required this.kind,
    required this.active,
    required this.hovered,
    required this.imageRepository,
  });

  final BrushProfile brush;
  final FeatureKind kind;
  final bool active;
  final bool hovered;
  final ImageRepository imageRepository;

  @override
  Widget build(BuildContext context) {
    final colors = context.squiggleTheme.colors;

    return BrushWheelTile(
      hovered: hovered,
      active: active,
      child: Stack(
        alignment: Alignment.center,
        children: [
          BrushSwatch(
            brush: brush,
            kind: kind,
            imageRepository: imageRepository,
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
    );
  }
}
