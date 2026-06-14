part of 'feature_kind.dart';

final class FeatureKindPolyline extends FeatureKind {
  const FeatureKindPolyline(
    this.localPoints, {
    super.strokeColor,
    super.fillColor,
    super.strokeWidth,
  });

  final List<Offset> localPoints;

  FeatureKindPolyline copyWith({
    List<Offset>? localPoints,
    Color? strokeColor,
    Color? fillColor,
    double? strokeWidth,
  }) {
    return FeatureKindPolyline(
      localPoints ?? this.localPoints,
      strokeColor: strokeColor ?? this.strokeColor,
      fillColor: fillColor ?? this.fillColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
    );
  }

  double get _hitRadius {
    if (hasVisibleStroke && hasVisibleFill) {
      return strokeWidth;
    }
    return strokeWidth / 2;
  }

  double get _selectionTolerance => _hitRadius + kPolylineHitSlop;

  @override
  Rect boundsFor(Feature feature) {
    if (localPoints.isEmpty) {
      return super.boundsFor(feature);
    }

    return envelopeOfPoints(
      worldPoints(feature.origin, localPoints),
      strokePadding: _hitRadius,
    );
  }

  Path _pathFor(Feature feature) {
    final path = Path();
    if (localPoints.isEmpty) {
      return path;
    }

    final first = feature.origin + localPoints.first;
    path.moveTo(first.dx, first.dy);
    for (final local in localPoints.skip(1)) {
      final world = feature.origin + local;
      path.lineTo(world.dx, world.dy);
    }
    return path;
  }

  @override
  bool hitTest(Feature feature, Offset worldPoint) {
    if (localPoints.length < 2) {
      return false;
    }

    final threshold = _selectionTolerance;
    final points = worldPoints(feature.origin, localPoints);
    for (var i = 0; i < points.length - 1; i++) {
      if (distanceToSegment(worldPoint, points[i], points[i + 1]) <= threshold) {
        return true;
      }
    }
    return false;
  }

  @override
  bool intersectsRect(Feature feature, Rect rect) {
    if (localPoints.length < 2) {
      return false;
    }

    final padded = rect.inflate(_selectionTolerance);
    final points = worldPoints(feature.origin, localPoints);
    for (var i = 0; i < points.length - 1; i++) {
      if (segmentIntersectsRect(points[i], points[i + 1], padded)) {
        return true;
      }
    }
    return false;
  }

  @override
  void applyBounds(Feature feature, Rect bounds) {
    final oldBounds = boundsFor(feature);
    final oldCenterlineBounds = oldBounds.deflate(_hitRadius);
    final newCenterlineBounds = bounds.deflate(_hitRadius);
    final scaledLocalPoints = localPoints.map((local) {
      final world = feature.origin + local;
      final nx = oldCenterlineBounds.width == 0
          ? 0.0
          : (world.dx - oldCenterlineBounds.left) / oldCenterlineBounds.width;
      final ny = oldCenterlineBounds.height == 0
          ? 0.0
          : (world.dy - oldCenterlineBounds.top) / oldCenterlineBounds.height;
      final newWorld = Offset(
        newCenterlineBounds.left + nx * newCenterlineBounds.width,
        newCenterlineBounds.top + ny * newCenterlineBounds.height,
      );
      return newWorld - bounds.topLeft;
    }).toList();

    feature.setBoundsDirect(bounds);
    feature.kind = copyWith(localPoints: scaledLocalPoints);
  }

  @override
  void paint(Feature feature, Canvas canvas) {
    if (localPoints.length < 2) {
      return;
    }

    final path = _pathFor(feature);

    if (hasVisibleStroke && hasVisibleFill) {
      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth * 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    if (hasVisibleStroke) {
      canvas.drawPath(
        path,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    if (hasVisibleFill) {
      canvas.drawPath(
        path,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }
}
