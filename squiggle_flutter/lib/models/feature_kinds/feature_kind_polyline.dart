part of 'feature_kind.dart';

final class FeatureKindPolyline extends FeatureKind
    with
        StrokeColorCapable,
        StrokeWidthCapable,
        StrokeTypeCapable,
        BindingCapable {
  FeatureKindPolyline(
    List<Offset> localPoints, {
    this.strokeColor = defaultFeatureStrokeColor,
    this.strokeWidth = defaultStrokeWidth,
    this.strokeType = StrokeType.solid,
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
        strokeType: _strokeTypeFromDataModel(content),
        startEndCap: _endCapFromDataModel(content, 'startEndCap'),
        endEndCap: _endCapFromDataModel(content, 'endEndCap'),
        startBinding: _bindingFromDataModel(content['startBinding']),
        endBinding: _bindingFromDataModel(content['endBinding']),
      );

  List<Offset> localPoints;
  @override
  Color strokeColor;

  @override
  double strokeWidth;

  @override
  StrokeType strokeType;
  LineEndCap startEndCap;
  LineEndCap endEndCap;
  NodeBinding? startBinding;
  NodeBinding? endBinding;

  /// Features mid-resolution; re-entry means a binding cycle.
  static final Set<Feature> _resolving = {};

  double get _hitRadius => strokeWidth / 2;

  double get _selectionTolerance => _hitRadius + kPolylineHitSlop;

  double get _boundsPadding {
    if (startEndCap != LineEndCap.arrow && endEndCap != LineEndCap.arrow) {
      return _hitRadius;
    }
    return math.max(
      _hitRadius,
      math.max(5.0, strokeWidth * 1.5) + _hitRadius / 2,
    );
  }

  double get _arrowLength => math.max(12.0, strokeWidth * 3);

  @override
  Iterable<NodeBinding> get bindings => [?startBinding, ?endBinding];

  @override
  Map<String, dynamic> toDataModel() => {
    'type': 'polyline',
    'localPoints': [
      for (final point in localPoints) {'x': point.dx, 'y': point.dy},
    ],
    'strokeColor': strokeColor.toARGB32(),
    'strokeWidth': strokeWidth,
    'strokeType': strokeType.name,
    'startEndCap': startEndCap.name,
    'endEndCap': endEndCap.name,
    if (startBinding case final binding?) 'startBinding': binding.toDataModel(),
    if (endBinding case final binding?) 'endBinding': binding.toDataModel(),
  };

  @override
  FeatureKindPolyline clone() => FeatureKindPolyline(
    localPoints,
    strokeColor: strokeColor,
    strokeWidth: strokeWidth,
    strokeType: strokeType,
    startEndCap: startEndCap,
    endEndCap: endEndCap,
    startBinding: startBinding,
    endBinding: endBinding,
  );

  /// Points in the feature's parent space, with bound ends on their targets.
  /// Missing targets and binding cycles leave the stored point in place.
  List<Offset> resolvedPoints(Feature feature) {
    final points = worldPoints(feature.origin, localPoints);
    final document = feature.document;
    if (points.length < 2 || document == null || bindings.isEmpty) {
      return points;
    }
    if (!_resolving.add(feature)) return points;
    try {
      final shift = feature.parent!.globalOrigin;
      final resolved = resolveBoundEnds(
        [for (final point in points) point + shift],
        start: startBinding?.target(document),
        end: endBinding?.target(document),
      );
      return [for (final point in resolved) point - shift];
    } finally {
      _resolving.remove(feature);
    }
  }

  @override
  void bakeBindings(Feature feature) {
    if (bindings.isEmpty) return;
    _setResolvedPoints(feature, resolvedPoints(feature));
  }

  @override
  void unbind(Feature feature, {required bool Function(NodeId) keep}) {
    bakeBindings(feature);
    if (startBinding case final binding? when !keep(binding.targetId)) {
      startBinding = null;
    }
    if (endBinding case final binding? when !keep(binding.targetId)) {
      endBinding = null;
    }
  }

  @override
  void rebindCopy(Feature copy, Feature source, Map<NodeId, NodeId> ids) {
    final sourceKind = source.kind as FeatureKindPolyline;
    final shift = copy.origin - source.origin;
    _setResolvedPoints(copy, [
      for (final point in sourceKind.resolvedPoints(source)) point + shift,
    ]);
    startBinding = startBinding?.remapped(ids);
    endBinding = endBinding?.remapped(ids);
  }

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
    final points = resolvedPoints(feature);
    if (pointIndex < 0 || pointIndex >= points.length) return;

    points[pointIndex] = worldPosition;
    setGeometry(
      feature,
      origin: points.first,
      localPoints: localPointsFromWorld(points, points.first),
    );
  }

  @override
  Rect boundsFor(Feature feature) {
    if (localPoints.isEmpty) {
      return super.boundsFor(feature);
    }

    return envelopeOfPoints(
      resolvedPoints(feature),
      strokePadding: _boundsPadding,
    );
  }

  @override
  bool hitTest(Feature feature, Offset worldPoint) {
    if (localPoints.length < 2) {
      return false;
    }

    final threshold = _selectionTolerance;
    final points = resolvedPoints(feature);
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
    final points = resolvedPoints(feature);
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
    final scaledLocalPoints = resolvedPoints(feature).map((world) {
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
      paintStroke(
        canvas,
        path,
        Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
        strokeType,
      );
      _paintArrowHeads(canvas, feature);
    }
  }

  @override
  Iterable<InspectorField> buildInspectorFields({Feature? feature}) {
    return [
      InspectorColorField(
        fieldKey: 'strokeColor',
        label: 'Stroke Color',
        value: strokeColor,
        onColorChanged: (color) {
          strokeColor = color;
        },
      ),
      InspectorStrokeTypeField(
        fieldKey: 'strokeType',
        label: 'Stroke Type',
        value: strokeType,
        onTypeChanged: (type) => strokeType = type,
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

  void _setResolvedPoints(Feature feature, List<Offset> points) {
    setGeometry(
      feature,
      origin: feature.origin,
      localPoints: [for (final point in points) point - feature.origin],
    );
  }

  static NodeBinding? _bindingFromDataModel(Object? raw) => raw == null
      ? null
      : NodeBinding.fromDataModel(Map<String, dynamic>.from(raw as Map));

  static LineEndCap _endCapFromDataModel(
    Map<String, dynamic> content,
    String key,
  ) => decodeStyleEnum(
    content[key],
    LineEndCap.values,
    fallback: LineEndCap.rounded,
  );

  Path _pathFor(Feature feature) {
    final path = Path();
    if (localPoints.isEmpty) {
      return path;
    }

    final points = resolvedPoints(feature);
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

  void _paintArrowHeads(Canvas canvas, Feature feature) {
    final points = resolvedPoints(feature);
    for (final arrow in _arrowPaths(points)) {
      canvas.drawPath(arrow, Paint()..color = strokeColor);
    }
  }
}
