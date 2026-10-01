import 'dart:math' as math;
import 'dart:ui';

import 'package:squiggle_flutter/models/stroke_type.dart';

void paintStroke(Canvas canvas, Path path, Paint paint, StrokeType type) {
  if (type == StrokeType.solid || paint.strokeWidth <= 0) {
    canvas.drawPath(path, paint);
    return;
  }

  final width = paint.strokeWidth;
  final dotPaint = Paint()
    ..color = paint.color
    ..style = PaintingStyle.fill;
  for (final metric in path.computeMetrics()) {
    if (metric.length == 0) continue;
    final spacing = width * (type == StrokeType.dashed ? 6 : 3);
    // Fit whole repeats around closed outlines to avoid overlapping at the seam.
    final count = math.max(
      1,
      metric.isClosed
          ? (metric.length / spacing).round()
          : (metric.length / spacing).ceil(),
    );
    final step = metric.isClosed ? metric.length / count : spacing;
    for (var i = 0; i < count; i++) {
      final distance = i * step;
      if (type == StrokeType.dashed) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            math.min(distance + step * 2 / 3, metric.length),
          ),
          paint,
        );
      } else {
        canvas.drawCircle(
          metric.getTangentForOffset(distance)!.position,
          width / 2,
          dotPaint,
        );
      }
    }
  }
}
