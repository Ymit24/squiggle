import 'package:flutter/widgets.dart';

const _gridUnit = 128.0;
const _minMajorScreenSize = 64.0;
const _maxMajorScreenSize = 160.0;
const _minorGridColor = Color(0xFF252525);
const _majorGridColor = Color(0xFF363636);

/// Paints a Unity-style adaptive world-space grid.
void paintAdaptiveGrid(
  Canvas canvas, {
  required Size size,
  required Offset location,
  required double zoom,
}) {
  if (zoom <= 0) return;

  var majorCellSize = _gridUnit;
  var majorScreenSize = majorCellSize / zoom;

  while (majorScreenSize < _minMajorScreenSize) {
    majorCellSize *= 2;
    majorScreenSize *= 2;
  }
  while (majorScreenSize > _maxMajorScreenSize) {
    majorCellSize /= 2;
    majorScreenSize /= 2;
  }

  final minorCellSize = majorCellSize / 4;
  final firstMinorGridX = (location.dx / minorCellSize).floor() * minorCellSize;
  final firstMinorGridY = (location.dy / minorCellSize).floor() * minorCellSize;
  final visibleWorld = Rect.fromLTWH(
    location.dx,
    location.dy,
    size.width * zoom,
    size.height * zoom,
  );

  final minorPaint = Paint()
    ..color = _minorGridColor
    ..style = PaintingStyle.fill;
  final majorPaint = Paint()
    ..color = _majorGridColor
    ..style = PaintingStyle.fill;

  final minorLineWidth = zoom * 0.6;
  final majorLineWidth = zoom * 1.2;

  for (
    var x = firstMinorGridX;
    x < visibleWorld.right + minorCellSize;
    x += minorCellSize
  ) {
    final isMajor =
        ((x / majorCellSize).round() * majorCellSize - x).abs() <
        minorCellSize / 100;
    canvas.drawRect(
      Rect.fromLTWH(
        x,
        visibleWorld.top,
        isMajor ? majorLineWidth : minorLineWidth,
        visibleWorld.height,
      ),
      isMajor ? majorPaint : minorPaint,
    );
  }
  for (
    var y = firstMinorGridY;
    y < visibleWorld.bottom + minorCellSize;
    y += minorCellSize
  ) {
    final isMajor =
        ((y / majorCellSize).round() * majorCellSize - y).abs() <
        minorCellSize / 100;
    canvas.drawRect(
      Rect.fromLTWH(
        visibleWorld.left,
        y,
        visibleWorld.width,
        isMajor ? majorLineWidth : minorLineWidth,
      ),
      isMajor ? majorPaint : minorPaint,
    );
  }
}
