part of 'feature_kind.dart';

final class FeatureKindPolyline extends FeatureKind with FeatureKindWithLabel {
  FeatureKindPolyline(
    this.localPoints, {
    super.strokeColor,
    super.fillColor,
    super.strokeWidth,
  });

  factory FeatureKindPolyline.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindPolyline(
        [
          for (final point in content['localPoints'] as List<dynamic>)
            _offsetFromDataModel(point),
        ],
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        fillColor: _colorFromDataModel(content, 'fillColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
      );

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'polyline',
    'localPoints': [
      for (final point in localPoints) {'x': point.dx, 'y': point.dy},
    ],
    'strokeColor': strokeColor.toARGB32(),
    'fillColor': fillColor.toARGB32(),
    'strokeWidth': strokeWidth,
  };

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

  void setGeometry(
    Feature feature, {
    required Offset origin,
    required List<Offset> localPoints,
  }) {
    feature.origin = origin;
    feature.kind = copyWith(localPoints: List.of(localPoints));
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
    feature.kind = copyWith(localPoints: scaledLocalPoints);
  }

  @override
  void paint(Feature feature, Canvas canvas, ImageRepository imageRepository) {
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
      if (label != null) {
        _paintLabel(feature, canvas, imageRepository);
      }
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
      if (label != null) {
        _paintLabel(feature, canvas, imageRepository);
      }
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
      if (label != null) {
        _paintLabel(feature, canvas, imageRepository);
      }
    }
  }

  void _paintLabel(
    Feature feature,
    Canvas canvas,
    ImageRepository imageRepository,
  ) {
    paintLabel(
      feature,
      canvas,
      imageRepository,
      beforeDraw: _cutOutLineBehindLabel,
    );
  }

  void _cutOutLineBehindLabel(
    Canvas canvas,
    Feature feature,
    Offset position,
    Paragraph paragraph,
  ) {
    if (label == null || label!.isEmpty) return;

    final boxes = paragraph.getBoxesForRange(0, label!.length);
    if (boxes.isEmpty) return;

    var labelBounds = boxes.first.toRect().shift(position);
    for (final box in boxes.skip(1)) {
      labelBounds = labelBounds.expandToInclude(box.toRect().shift(position));
    }

    canvas.save();
    canvas.clipRect(labelBounds.inflate(1));
    canvas.drawPath(
      _pathFor(feature),
      Paint()
        ..blendMode = BlendMode.clear
        ..style = PaintingStyle.stroke
        ..strokeWidth = hasVisibleStroke && hasVisibleFill
            ? strokeWidth * 2
            : strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.restore();
  }

  @override
  String? label;

  @override
  Offset getLabelPosition(Rect worldBounds, Paragraph fillParagraph) {
    if (localPoints.isEmpty) {
      return Offset(
        worldBounds.center.dx - fillParagraph.width / 2,
        worldBounds.center.dy - fillParagraph.height / 2,
      );
    }

    // Find the midpoint by distance along the polyline, rather than using
    // the center of its bounding box. The latter is not generally on a
    // polyline with bends or unevenly sized segments.
    var totalLength = 0.0;
    for (var i = 0; i < localPoints.length - 1; i++) {
      totalLength += (localPoints[i + 1] - localPoints[i]).distance;
    }

    var midpoint = localPoints.first;
    if (totalLength > 0) {
      var distanceToMidpoint = totalLength / 2;
      for (var i = 0; i < localPoints.length - 1; i++) {
        final start = localPoints[i];
        final end = localPoints[i + 1];
        final segment = end - start;
        final segmentLength = segment.distance;

        if (segmentLength == 0) continue;
        if (distanceToMidpoint <= segmentLength) {
          final t = distanceToMidpoint / segmentLength;
          midpoint = Offset(
            start.dx + segment.dx * t,
            start.dy + segment.dy * t,
          );
          break;
        }
        distanceToMidpoint -= segmentLength;
      }
    }

    // worldBounds is the translated envelope of localPoints. Its top-left
    // lets us convert the local midpoint to world coordinates without the
    // Feature (which is not part of this callback's API).
    var minX = localPoints.first.dx;
    var minY = localPoints.first.dy;
    for (final point in localPoints.skip(1)) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
    }
    final worldMidpoint =
        worldBounds.topLeft +
        Offset(
          midpoint.dx - minX + _hitRadius,
          midpoint.dy - minY + _hitRadius,
        );

    return Offset(
      worldMidpoint.dx - fillParagraph.width / 2,
      worldMidpoint.dy - fillParagraph.height / 2,
    );
  }

  @override
  // TODO: implement fontSize
  double get fontSize => 36;

  @override
  // TODO: implement horizontalAlignment
  TextHorizontalAlignment get horizontalAlignment =>
      TextHorizontalAlignment.center;

  @override
  // TODO: implement verticalAlignment
  TextVerticalAlignment get verticalAlignment => TextVerticalAlignment.center;
}
