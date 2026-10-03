import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/style_color_swatch.dart';
import 'package:squiggle_flutter/models/stroke_type.dart';
import 'package:squiggle_flutter/painting/stroke_painter.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class StrokeTypeSelector extends StatelessWidget {
  const StrokeTypeSelector({
    super.key,
    required this.activeType,
    required this.isMixed,
    required this.onTypeSelected,
    this.enabled = true,
  });

  final StrokeType? activeType;
  final bool isMixed;
  final ValueChanged<StrokeType> onTypeSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing.swatchGap,
      children: [
        for (final type in StrokeType.values)
          Tooltip(
            message: switch (type) {
              StrokeType.solid => 'Solid',
              StrokeType.dashed => 'Dashed',
              StrokeType.dotted => 'Dotted',
            },
            child: StyleColorSwatch(
              color: theme.colors.base,
              isActive: !isMixed && activeType == type,
              enabled: enabled,
              onPressed: () => onTypeSelected(type),
              overlay: CustomPaint(
                painter: _StrokeTypePreviewPainter(
                  type: type,
                  color: !isMixed && activeType == type
                      ? theme.colors.text
                      : theme.colors.subtext0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _StrokeTypePreviewPainter extends CustomPainter {
  const _StrokeTypePreviewPainter({required this.type, required this.color});

  final StrokeType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    paintStroke(
      canvas,
      Path()
        ..moveTo(size.width * 0.2, size.height / 2)
        ..lineTo(size.width * 0.8, size.height / 2),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
      type,
    );
  }

  @override
  bool shouldRepaint(covariant _StrokeTypePreviewPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}
