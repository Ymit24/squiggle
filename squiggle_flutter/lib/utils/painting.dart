import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

void paintDashedRect(Canvas canvas, Rect bounds) {
  const dashLength = 8.0;
  const gapLength = 4.0;
  final paint = Paint()
    ..color = SquiggleColors.accent
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;

  void drawDashedLine(Offset start, Offset end) {
    final delta = end - start;
    final length = delta.distance;
    if (length == 0) return;
    final direction = delta / length;
    var drawn = 0.0;
    var drawing = true;
    while (drawn < length) {
      final segment = drawing ? dashLength : gapLength;
      final next = (drawn + segment).clamp(0.0, length);
      if (drawing) {
        canvas.drawLine(
          start + direction * drawn,
          start + direction * next,
          paint,
        );
      }
      drawn = next;
      drawing = !drawing;
    }
  }

  drawDashedLine(bounds.topLeft, bounds.topRight);
  drawDashedLine(bounds.topRight, bounds.bottomRight);
  drawDashedLine(bounds.bottomRight, bounds.bottomLeft);
  drawDashedLine(bounds.bottomLeft, bounds.topLeft);
}
