import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/brush_wheel/brush_wheel_geometry.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_wheel_add_slot.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_wheel_label.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_wheel_slot.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// The brush quick picker: one slot per brush around a cancel hub, plus a
/// trailing "new brush" slot when [canCreate], with the pending change named
/// below. Purely visual; the host owns input. A [hoveredIndex] equal to
/// `brushes.length` is the new brush slot.
class BrushWheel extends StatelessWidget {
  const BrushWheel({
    super.key,
    required this.brushes,
    required this.activeId,
    required this.hoveredIndex,
    required this.canCreate,
    required this.kind,
    required this.imageRepository,
  });

  final List<BrushProfile> brushes;
  final String activeId;
  final int? hoveredIndex;
  final bool canCreate;
  final FeatureKind kind;
  final ImageRepository imageRepository;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;
    const radius = BrushWheelGeometry.outerRadius;
    final slotCount = brushes.length + (canCreate ? 1 : 0);
    final hoveringAdd = canCreate && hoveredIndex == brushes.length;
    final hovered = hoveredIndex == null || hoveringAdd
        ? null
        : brushes[hoveredIndex!];
    return SizedBox.fromSize(
      size: BrushWheelGeometry.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: BrushWheelGeometry.discSize,
            painter: _DiscPainter(colors, slotCount, hoveredIndex),
          ),
          for (final (index, brush) in brushes.indexed)
            Positioned.fromRect(
              rect: Rect.fromCenter(
                center:
                    const Offset(radius, radius) +
                    BrushWheelGeometry.slotCenter(index, slotCount),
                width: BrushWheelGeometry.slotSize,
                height: BrushWheelGeometry.slotSize,
              ),
              child: BrushWheelSlot(
                key: ValueKey(brush.id),
                brush: brush,
                kind: kind,
                active: brush.id == activeId,
                hovered: index == hoveredIndex,
                imageRepository: imageRepository,
              ),
            ),
          if (canCreate)
            Positioned.fromRect(
              rect: Rect.fromCenter(
                center:
                    const Offset(radius, radius) +
                    BrushWheelGeometry.slotCenter(brushes.length, slotCount),
                width: BrushWheelGeometry.slotSize,
                height: BrushWheelGeometry.slotSize,
              ),
              child: BrushWheelAddSlot(hovered: hoveringAdd),
            ),
          Positioned.fromRect(
            rect: Rect.fromCircle(
              center: const Offset(radius, radius),
              radius: BrushWheelGeometry.hubSize / 2,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.mantle,
                shape: BoxShape.circle,
                border: Border.all(color: colors.surface1),
              ),
              child: hovered == null && !hoveringAdd
                  ? Icon(Icons.close, size: 14, color: colors.subtext0)
                  : null,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: radius * 2 + BrushWheelGeometry.labelGap,
            height: BrushWheelGeometry.labelHeight,
            child: Center(
              child: BrushWheelLabel(
                active: brushes.firstWhere((brush) => brush.id == activeId),
                hovered: hovered,
                adding: hoveringAdd,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscPainter extends CustomPainter {
  _DiscPainter(this.colors, this.count, this.hoveredIndex);

  final SquiggleColorScheme colors;
  final int count;
  final int? hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const radius = BrushWheelGeometry.outerRadius - 1;
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = colors.mantle.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = colors.surface1
        ..style = PaintingStyle.stroke,
    );
    final index = hoveredIndex;
    if (index == null) {
      return;
    }

    // Highlight the whole slice, which is the real hit area, not just the slot.
    final sweep = BrushWheelGeometry.sweep(count);
    final start = BrushWheelGeometry.slotAngle(index, count) - sweep / 2;
    const inner = BrushWheelGeometry.innerRadius + 2;
    final wedge = Path()
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius - 1),
        start,
        sweep,
        true,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: inner),
        start + sweep,
        -sweep,
        false,
      )
      ..close();
    canvas.drawPath(
      wedge,
      Paint()..color = colors.accent.withValues(alpha: 0.14),
    );
  }

  @override
  bool shouldRepaint(_DiscPainter oldDelegate) =>
      colors != oldDelegate.colors ||
      count != oldDelegate.count ||
      hoveredIndex != oldDelegate.hoveredIndex;
}
