part of 'feature_kind.dart';

final class FeatureKindPolyline extends FeatureKind
    with StrokeColorCapable, StrokeWidthCapable, BindCapable {
  FeatureKindPolyline(
    List<Offset> localPoints, {
    this.strokeColor = defaultFeatureStrokeColor,
    this.strokeWidth = defaultStrokeWidth,
    this.startEndCap = LineEndCap.rounded,
    this.endEndCap = LineEndCap.rounded,
    this.startBinding,
    this.endBinding,
  }) : localPoints = List.of(localPoints);

  factory FeatureKindPolyline.fromDataModel(Map<String, dynamic> content) =>
      FeatureKindPolyline(
        [
          for (final point in content['localPoints'] as List<dynamic>)
            _offsetFromDataModel(point),
        ],
        strokeColor: _colorFromDataModel(content, 'strokeColor'),
        strokeWidth: _doubleFromDataModel(content, 'strokeWidth'),
        startEndCap: _endCapFromDataModel(content, 'startEndCap'),
        endEndCap: _endCapFromDataModel(content, 'endEndCap'),
        startBinding: content['startBinding'] == null
            ? null
            : NodeBinding.fromJson(
                Map<String, dynamic>.from(content['startBinding'] as Map),
              ),
        endBinding: content['endBinding'] == null
            ? null
            : NodeBinding.fromJson(
                Map<String, dynamic>.from(content['endBinding'] as Map),
              ),
      );

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'polyline',
    'localPoints': [
      for (final point in localPoints) {'x': point.dx, 'y': point.dy},
    ],
    'strokeColor': strokeColor.toARGB32(),
    'strokeWidth': strokeWidth,
    'startEndCap': startEndCap.name,
    'endEndCap': endEndCap.name,
    if (startBinding != null) 'startBinding': startBinding!.toJson(),
    if (endBinding != null) 'endBinding': endBinding!.toJson(),
  };

  @override
  FeatureKindPolyline clone() => FeatureKindPolyline(
    localPoints,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
    startEndCap: startEndCap,
    endEndCap: endEndCap,
    startBinding: startBinding,
    endBinding: endBinding,
  );

  List<Offset> localPoints;
  @override
  Color strokeColor;

  @override
  double strokeWidth;
  LineEndCap startEndCap;
  LineEndCap endEndCap;
  NodeBinding? startBinding;
  NodeBinding? endBinding;

  @override
  Iterable<NodeBinding> get bindings sync* {
    if (startBinding case final binding?) yield binding;
    if (endBinding case final binding?) yield binding;
  }

  @override
  void onBoundNodeBoundsUpdate(Feature feature, Node target) {
    final parentOrigin = feature.parent?.globalOrigin ?? Offset.zero;
    if (startBinding?.targetId == target.id && localPoints.isNotEmpty) {
      setPoint(
        feature,
        0,
        startBinding!.pointOn(target.globalBounds()) - parentOrigin,
      );
    }
    if (endBinding?.targetId == target.id && localPoints.isNotEmpty) {
      setPoint(
        feature,
        localPoints.length - 1,
        endBinding!.pointOn(target.globalBounds()) - parentOrigin,
      );
    }
  }

  static LineEndCap _endCapFromDataModel(
    Map<String, dynamic> content,
    String key,
  ) => LineEndCap.values.asNameMap()[content[key]] ?? LineEndCap.rounded;

  void setGeometry(
    Feature feature, {
    required Offset origin,
    required List<Offset> localPoints,
  }) {
    feature.editGeometry((edit) {
      edit.origin = origin;
      this.localPoints = List.of(localPoints);
      edit.size = boundsForOrigin(origin).size;
    });
  }

  Rect boundsForOrigin(Offset origin) => envelopeOfPoints(
    worldPoints(origin, localPoints),
    strokePadding: _boundsPadding,
  );

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
      strokePadding: _boundsPadding,
    );
  }

  double get _boundsPadding {
    if (startEndCap != LineEndCap.arrow && endEndCap != LineEndCap.arrow) {
      return _hitRadius;
    }
    return math.max(
      _hitRadius,
      math.max(5.0, strokeWidth * 1.5) + _hitRadius / 2,
    );
  }

  Path _pathFor(Feature feature) {
    final path = Path();
    if (localPoints.isEmpty) {
      return path;
    }

    final points = worldPoints(feature.origin, localPoints);
    if (startEndCap == LineEndCap.arrow) {
      final direction = _endpointDirection(points, fromStart: true);
      if (direction != null) {
        points[0] -= direction * _arrowLength;
      }
    }
    if (endEndCap == LineEndCap.arrow) {
      final direction = _endpointDirection(points, fromStart: false);
      if (direction != null) {
        points[points.length - 1] -= direction * _arrowLength;
      }
    }

    final first = points.first;
    path.moveTo(first.dx, first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
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
    return _arrowPaths(points).any((path) => path.contains(worldPoint));
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
    final oldCenterlineBounds = oldBounds.deflate(_boundsPadding);
    final newCenterlineBounds = bounds.deflate(_boundsPadding);
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

    feature.editGeometry((edit) {
      edit.origin = bounds.topLeft;
      edit.size = bounds.size;
      localPoints = scaledLocalPoints;
    });
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
      _paintArrowHeads(canvas, feature);
    }
  }

  Iterable<Path> _arrowPaths(List<Offset> points) sync* {
    if (startEndCap == LineEndCap.arrow) {
      final direction = _endpointDirection(points, fromStart: true);
      if (direction != null) yield _arrowPath(points.first, direction);
    }
    if (endEndCap == LineEndCap.arrow) {
      final direction = _endpointDirection(points, fromStart: false);
      if (direction != null) yield _arrowPath(points.last, direction);
    }
  }

  Offset? _endpointDirection(List<Offset> points, {required bool fromStart}) {
    final tip = fromStart ? points.first : points.last;
    final candidates = fromStart ? points.skip(1) : points.reversed.skip(1);
    for (final point in candidates) {
      final delta = tip - point;
      if (delta.distanceSquared > 0) return delta / delta.distance;
    }
    return null;
  }

  Path _arrowPath(Offset tip, Offset direction) {
    final halfWidth = math.max(5.0, strokeWidth * 1.5);
    final base = tip - direction * _arrowLength;
    final normal = Offset(-direction.dy, direction.dx) * halfWidth;
    final upper = base + normal;
    final lower = base - normal;
    final cornerRadius = math.min(4.0, strokeWidth / 2);
    final tipUpper = _pointToward(tip, upper, cornerRadius);
    final upperTip = _pointToward(upper, tip, cornerRadius);
    final upperLower = _pointToward(upper, lower, cornerRadius);
    final lowerUpper = _pointToward(lower, upper, cornerRadius);
    final lowerTip = _pointToward(lower, tip, cornerRadius);
    return Path()
      ..moveTo(tip.dx, tip.dy)
      ..quadraticBezierTo(tip.dx, tip.dy, tipUpper.dx, tipUpper.dy)
      ..lineTo(upperTip.dx, upperTip.dy)
      ..quadraticBezierTo(upper.dx, upper.dy, upperLower.dx, upperLower.dy)
      ..lineTo(lowerUpper.dx, lowerUpper.dy)
      ..quadraticBezierTo(lower.dx, lower.dy, lowerTip.dx, lowerTip.dy)
      ..quadraticBezierTo(tip.dx, tip.dy, tip.dx, tip.dy)
      ..close();
  }

  Offset _pointToward(Offset from, Offset to, double distance) {
    final delta = to - from;
    return from + delta / delta.distance * math.min(distance, delta.distance);
  }

  double get _arrowLength => math.max(12.0, strokeWidth * 3);

  void _paintArrowHeads(Canvas canvas, Feature feature) {
    final points = worldPoints(feature.origin, localPoints);
    for (final arrow in _arrowPaths(points)) {
      canvas.drawPath(arrow, Paint()..color = strokeColor);
    }
  }

  @override
  Iterable<InspectorField> buildInspectorFields() {
    return [
      InspectorColorField(
        fieldKey: 'strokeColor',
        label: 'Stroke Color',
        value: strokeColor,
        onColorChanged: (color) {
          strokeColor = color;
        },
      ),
      InspectorWidthField(
        fieldKey: 'strokeWidth',
        label: 'Stroke Width',
        value: strokeWidth,
        onWidthChanged: (width) {
          strokeWidth = width;
        },
      ),
      InspectorEndCapField(
        fieldKey: 'startEndCap',
        label: 'Start End Cap',
        isStart: true,
        value: startEndCap,
        onEndCapChanged: (endCap) {
          startEndCap = endCap;
        },
      ),
      InspectorEndCapField(
        fieldKey: 'endEndCap',
        label: 'End End Cap',
        isStart: false,
        value: endEndCap,
        onEndCapChanged: (endCap) {
          endEndCap = endCap;
        },
      ),
    ];
  }
}
