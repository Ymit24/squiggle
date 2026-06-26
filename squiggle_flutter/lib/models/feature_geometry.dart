import 'dart:math' show atan2, cos, max, pi, sin;
import 'dart:ui';

/// Extra world-space tolerance when hit-testing polyline segments.
const kPolylineHitSlop = 4.0;

/// Minimum envelope dimension so degenerate lines still expose resize handles.
const kMinEnvelopeDimension = 1.0;

List<Offset> worldPoints(Offset origin, List<Offset> localPoints) {
  return [for (final local in localPoints) origin + local];
}

List<Offset> localPointsFromWorld(List<Offset> worldPoints, Offset reference) {
  if (worldPoints.isEmpty) {
    return const [];
  }
  return [
    Offset.zero,
    for (final point in worldPoints.skip(1)) point - reference,
  ];
}

Rect envelopeOfPoints(List<Offset> worldPoints, {required double strokePadding}) {
  if (worldPoints.isEmpty) {
    return Rect.fromLTWH(0, 0, kMinEnvelopeDimension, kMinEnvelopeDimension);
  }

  var minX = worldPoints.first.dx;
  var maxX = worldPoints.first.dx;
  var minY = worldPoints.first.dy;
  var maxY = worldPoints.first.dy;

  for (final point in worldPoints.skip(1)) {
    minX = minX < point.dx ? minX : point.dx;
    maxX = maxX > point.dx ? maxX : point.dx;
    minY = minY < point.dy ? minY : point.dy;
    maxY = maxY > point.dy ? maxY : point.dy;
  }

  final envelope = Rect.fromLTRB(minX, minY, maxX, maxY).inflate(strokePadding);
  final width = envelope.width < kMinEnvelopeDimension
      ? kMinEnvelopeDimension
      : envelope.width;
  final height = envelope.height < kMinEnvelopeDimension
      ? kMinEnvelopeDimension
      : envelope.height;

  return Rect.fromLTWH(envelope.left, envelope.top, width, height);
}

double distanceToSegment(Offset point, Offset segmentStart, Offset segmentEnd) {
  final ab = segmentEnd - segmentStart;
  final abLengthSquared = ab.dx * ab.dx + ab.dy * ab.dy;
  if (abLengthSquared == 0) {
    return (point - segmentStart).distance;
  }

  final t = ((point.dx - segmentStart.dx) * ab.dx +
          (point.dy - segmentStart.dy) * ab.dy) /
      abLengthSquared;
  final clamped = t.clamp(0.0, 1.0);
  final closest = Offset(
    segmentStart.dx + ab.dx * clamped,
    segmentStart.dy + ab.dy * clamped,
  );
  return (point - closest).distance;
}

bool segmentIntersectsRect(Offset segmentStart, Offset segmentEnd, Rect rect) {
  if (rect.contains(segmentStart) || rect.contains(segmentEnd)) {
    return true;
  }

  final topLeft = rect.topLeft;
  final topRight = rect.topRight;
  final bottomRight = rect.bottomRight;
  final bottomLeft = rect.bottomLeft;

  return segmentsIntersect(segmentStart, segmentEnd, topLeft, topRight) ||
      segmentsIntersect(segmentStart, segmentEnd, topRight, bottomRight) ||
      segmentsIntersect(segmentStart, segmentEnd, bottomRight, bottomLeft) ||
      segmentsIntersect(segmentStart, segmentEnd, bottomLeft, topLeft);
}

bool segmentsIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
  final d1 = direction(b1, b2, a1);
  final d2 = direction(b1, b2, a2);
  final d3 = direction(a1, a2, b1);
  final d4 = direction(a1, a2, b2);

  if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
      ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
    return true;
  }

  if (d1 == 0 && onSegment(b1, b2, a1)) return true;
  if (d2 == 0 && onSegment(b1, b2, a2)) return true;
  if (d3 == 0 && onSegment(a1, a2, b1)) return true;
  if (d4 == 0 && onSegment(a1, a2, b2)) return true;

  return false;
}

double direction(Offset segmentStart, Offset segmentEnd, Offset point) {
  return (point.dx - segmentStart.dx) * (segmentEnd.dy - segmentStart.dy) -
      (segmentEnd.dx - segmentStart.dx) * (point.dy - segmentStart.dy);
}

bool onSegment(Offset segmentStart, Offset segmentEnd, Offset point) {
  return point.dx <= (segmentStart.dx > segmentEnd.dx
              ? segmentStart.dx
              : segmentEnd.dx) &&
      point.dx >= (segmentStart.dx < segmentEnd.dx
              ? segmentStart.dx
              : segmentEnd.dx) &&
      point.dy <= (segmentStart.dy > segmentEnd.dy
              ? segmentStart.dy
              : segmentEnd.dy) &&
      point.dy >= (segmentStart.dy < segmentEnd.dy
              ? segmentStart.dy
              : segmentEnd.dy);
}

/// Builds a square rect from two opposite corners.
Rect squareRectFromPoints(Offset start, Offset end) {
  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  final side = max(dx.abs(), dy.abs());
  final signX = dx == 0 ? 1.0 : dx.sign;
  final signY = dy == 0 ? 1.0 : dy.sign;
  return Rect.fromPoints(
    start,
    Offset(start.dx + side * signX, start.dy + side * signY),
  );
}

/// Snaps [point] to the nearest 45° ray from [origin], preserving distance.
Offset snapPointTo45DegreeAngle(Offset origin, Offset point) {
  final dx = point.dx - origin.dx;
  final dy = point.dy - origin.dy;
  final distance = Offset(dx, dy).distance;
  if (distance == 0) {
    return point;
  }

  const snapIncrement = pi / 4;
  final angle = atan2(dy, dx);
  final snappedAngle = (angle / snapIncrement).round() * snapIncrement;
  return Offset(
    origin.dx + cos(snappedAngle) * distance,
    origin.dy + sin(snappedAngle) * distance,
  );
}

/// Locks movement to horizontal or vertical axis relative to [dragStart].
Offset constrainMoveToAxis(Offset dragStart, Offset current) {
  final dx = current.dx - dragStart.dx;
  final dy = current.dy - dragStart.dy;
  if (dx.abs() >= dy.abs()) {
    return Offset(current.dx, dragStart.dy);
  }
  return Offset(dragStart.dx, current.dy);
}

/// Corner resize with a fixed [anchor] and locked width/height ratio.
Rect rectFromAnchorWithAspectRatio(
  Offset anchor,
  Offset dragged,
  double aspectRatio,
) {
  if (aspectRatio <= 0) {
    return Rect.fromPoints(anchor, dragged);
  }

  var dx = dragged.dx - anchor.dx;
  var dy = dragged.dy - anchor.dy;
  if (dx == 0 && dy == 0) {
    return Rect.fromPoints(anchor, dragged);
  }

  final absDx = dx.abs();
  final absDy = dy.abs();
  final effectiveRatio = absDy == 0 ? double.infinity : absDx / absDy;

  late double width;
  late double height;
  if (effectiveRatio > aspectRatio) {
    width = absDx;
    height = width / aspectRatio;
  } else {
    height = absDy;
    width = height * aspectRatio;
  }

  final signX = dx == 0 ? 1.0 : dx.sign;
  final signY = dy == 0 ? 1.0 : dy.sign;
  return Rect.fromPoints(
    anchor,
    Offset(anchor.dx + width * signX, anchor.dy + height * signY),
  );
}

/// Edge resize with aspect ratio locked; the opposite edge stays fixed.
Rect edgeResizeWithAspectRatio(
  Rect bounds,
  Offset dragged, {
  required bool resizeTop,
  required bool resizeBottom,
  required bool resizeLeft,
  required bool resizeRight,
  required double aspectRatio,
}) {
  if (aspectRatio <= 0) {
    return bounds;
  }

  if (resizeTop || resizeBottom) {
    final fixedY = resizeTop ? bounds.bottom : bounds.top;
    final newHeight = (dragged.dy - fixedY).abs();
    final newWidth = newHeight * aspectRatio;
    final centerX = bounds.center.dx;
    final top = resizeTop ? fixedY - newHeight : fixedY;
    return Rect.fromLTWH(centerX - newWidth / 2, top, newWidth, newHeight);
  }

  final fixedX = resizeLeft ? bounds.right : bounds.left;
  final newWidth = (dragged.dx - fixedX).abs();
  final newHeight = newWidth / aspectRatio;
  final centerY = bounds.center.dy;
  final left = resizeLeft ? fixedX - newWidth : fixedX;
  return Rect.fromLTWH(left, centerY - newHeight / 2, newWidth, newHeight);
}

/// Symmetric resize from [center] with aspect ratio locked.
Rect symmetricRectWithAspectRatio(
  Offset center,
  Offset dragged,
  double aspectRatio, {
  required bool resizeHorizontal,
  required bool resizeVertical,
}) {
  if (aspectRatio <= 0) {
    return Rect.fromCenter(center: center, width: 0, height: 0);
  }

  if (resizeHorizontal && resizeVertical) {
    final halfWidth = (dragged.dx - center.dx).abs();
    final halfHeight = (dragged.dy - center.dy).abs();
    final effectiveRatio =
        halfHeight == 0 ? double.infinity : halfWidth / halfHeight;

    late double width;
    late double height;
    if (effectiveRatio > aspectRatio) {
      width = halfWidth * 2;
      height = width / aspectRatio;
    } else {
      height = halfHeight * 2;
      width = height * aspectRatio;
    }
    return Rect.fromCenter(center: center, width: width, height: height);
  }

  if (resizeVertical) {
    final height = (dragged.dy - center.dy).abs() * 2;
    final width = height * aspectRatio;
    return Rect.fromCenter(center: center, width: width, height: height);
  }

  final width = (dragged.dx - center.dx).abs() * 2;
  final height = width / aspectRatio;
  return Rect.fromCenter(center: center, width: width, height: height);
}
