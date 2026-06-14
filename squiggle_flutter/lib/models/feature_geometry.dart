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
