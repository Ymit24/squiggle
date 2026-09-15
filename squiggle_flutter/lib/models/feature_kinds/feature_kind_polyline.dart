part of 'feature_kind.dart';

final class FeatureKindPolyline extends FeatureKind
    with StrokeColorCapable, StrokeWidthCapable {
  FeatureKindPolyline(
    List<Offset> localPoints, {
    this.strokeColor = defaultFeatureStrokeColor,
    this.strokeWidth = defaultStrokeWidth,
  }) : localPoints = List.of(localPoints);

  factory FeatureKindPolyline.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindPolyline(
        [
          for (final point in content['localPoints'] as List<dynamic>)
            _offsetFromDataModel(point),
        ],
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
      );

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'polyline',
    'localPoints': [
      for (final point in localPoints) {'x': point.dx, 'y': point.dy},
    ],
    'strokeColor': strokeColor.toARGB32(),
    'strokeWidth': strokeWidth,
  };

  @override
  FeatureKindPolyline clone() => FeatureKindPolyline(
    localPoints,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
  );

  List<Offset> localPoints;
  @override
  Color strokeColor;
  @override
  double strokeWidth;

  void setGeometry(
    Feature feature, {
    required Offset origin,
    required List<Offset> localPoints,
  }) {
    feature.origin = origin;
    this.localPoints = List.of(localPoints);
    feature.size = feature.localBounds().size;
  }

  void setPoint(Feature feature, int pointIndex, Offset worldPosition) {
    final points = worldPoints(feature.origin, localPoints);
    if (pointIndex < 0 || pointIndex >= points.length) return;

    points[pointIndex] = worldPosition;
    setGeometry(
      feature,
      origin: points.first,
      localPoints: localPointsFromWorld(points, points.first),
    );
  }

  double get _hitRadius => strokeWidth / 2;

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
      if (distanceToSegment(worldPoint, points[i], points[i + 1]) <=
          threshold) {
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

    feature.setBounds(bounds);
    localPoints = scaledLocalPoints;
  }

  @override
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
    if (localPoints.length < 2) {
      return;
    }

    final path = _pathFor(feature);

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
    }
  }
}
