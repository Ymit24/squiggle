import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_binding.dart';
import 'package:squiggle_flutter/tools/bind_target.dart';
import 'package:squiggle_flutter/tools/select_tool/selection_painter.dart';

/// Tracks the nodes under the ends of a line being drawn, snaps the ends onto
/// them, and binds the finished line to them.
class LineEndSnapper {
  Node? _start;
  Node? _end;

  /// Shows where a line started at [worldPoint] would attach.
  void hover(EditorContext context, Offset worldPoint) {
    _start = bindTargetAt(context, worldPoint);
    _end = null;
  }

  /// [points] with the ends moved onto the nodes beneath them.
  List<Offset> snap(EditorContext context, List<Offset> points) {
    _start = bindTargetAt(context, points.first);
    _end = points.length < 2
        ? null
        : bindTargetAt(context, points.last, exclude: _start?.id);
    if (points.length < 2) return points;
    return resolveBoundEnds(points, start: _start, end: _end);
  }

  /// Binds [kind]'s ends to the nodes found by the last [snap].
  void bind(FeatureKindPolyline kind) {
    kind
      ..startBinding = _bindingTo(_start)
      ..endBinding = _bindingTo(_end);
  }

  void paint(Canvas canvas, Camera camera) {
    for (final target in {?_start, ?_end}) {
      SelectionPainter.paintBindTarget(canvas, camera, target);
    }
  }

  void clear() {
    _start = null;
    _end = null;
  }

  NodeBinding? _bindingTo(Node? target) =>
      target == null ? null : NodeBinding(target.id);
}
