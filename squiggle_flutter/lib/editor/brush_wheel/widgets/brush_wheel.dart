import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/brush_wheel/brush_wheel_geometry.dart';
import 'package:squiggle_flutter/editor/brush_wheel/widgets/brush_wheel_slot.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// The brush quick picker: one slot per brush around a cancel hub, with the
/// pending change named below. Purely visual; the host owns input.
class BrushWheel extends StatelessWidget {
  const BrushWheel({
    super.key,
    required this.brushes,
    required this.activeId,
    required this.hoveredIndex,
    required this.kind,
    required this.imageRepository,
  });

  final List<BrushProfile> brushes;
  final String activeId;
  final int? hoveredIndex;
  final FeatureKind kind;
  final ImageRepository imageRepository;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;
    const radius = BrushWheelGeometry.outerRadius;
    final hovered = hoveredIndex == null ? null : brushes[hoveredIndex!];
    return SizedBox.fromSize(
      size: BrushWheelGeometry.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: BrushWheelGeometry.discSize,
            painter: _DiscPainter(colors, brushes.length, hoveredIndex),
          ),
          for (final (index, brush) in brushes.indexed)
            Positioned.fromRect(
              rect: Rect.fromCenter(
                center:
                    const Offset(radius, radius) +
                    BrushWheelGeometry.slotCenter(index, brushes.length),
                width: BrushWheelGeometry.slotSize,
                height: BrushWheelGeometry.slotSize,
              ),
              child: BrushWheelSlot(
                key: ValueKey(brush.id),
                brush: brush,
                number: index + 1,
                kind: kind,
                active: brush.id == activeId,
                hovered: index == hoveredIndex,
                imageRepository: imageRepository,
              ),
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
              child: hovered == null
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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.mantle,
                  border: Border.all(color: colors.surface1),
                  borderRadius: BorderRadius.circular(
                    BrushWheelGeometry.labelHeight / 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Center(
                    widthFactor: 1,
                    child: Text.rich(
                      _label(hovered, colors),
                      key: const ValueKey('brush-wheel-label'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.typography.menuItemLabel.copyWith(
                        color: colors.text,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextSpan _label(BrushProfile? hovered, SquiggleColorScheme colors) {
    final muted = TextStyle(color: colors.subtext0);
    if (hovered == null) {
      return TextSpan(text: 'Release to cancel', style: muted);
    }
    if (hovered.id == activeId) {
      return TextSpan(
        text: hovered.name,
        children: [TextSpan(text: ' · current', style: muted)],
      );
    }
    final active = brushes.firstWhere((brush) => brush.id == activeId);
    return TextSpan(
      children: [
        TextSpan(text: '${active.name} → ', style: muted),
        TextSpan(text: hovered.name),
      ],
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
    if (index == null) return;
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
