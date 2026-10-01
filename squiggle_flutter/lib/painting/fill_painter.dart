import 'dart:ui';

import 'package:squiggle_flutter/models/fill_type.dart';

void paintFill(
  Canvas canvas,
  Path path,
  Paint paint,
  FillType type, {
  double spacing = 12,
  double lineWidth = 1.5,
}) {
  assert(spacing > 0);
  if (type == FillType.solid) {
    canvas.drawPath(path, paint);
    return;
  }

  final bounds = path.getBounds();
  if (bounds.isEmpty || paint.color.a == 0) return;
  final linePaint = Paint()
    ..color = paint.color
    ..style = PaintingStyle.stroke
    ..strokeWidth = lineWidth;
  canvas.save();
  canvas.clipPath(path);
  for (var x = -bounds.height; x < bounds.width; x += spacing) {
    canvas.drawLine(
      Offset(bounds.left + x, bounds.bottom),
      Offset(bounds.left + x + bounds.height, bounds.top),
      linePaint,
    );
    if (type == FillType.crosshatch) {
      canvas.drawLine(
        Offset(bounds.left + x, bounds.top),
        Offset(bounds.left + x + bounds.height, bounds.bottom),
        linePaint,
      );
    }
  }
  canvas.restore();
}
