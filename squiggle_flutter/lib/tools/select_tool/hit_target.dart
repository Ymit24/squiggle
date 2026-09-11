import 'package:squiggle_flutter/models/node.dart';

import 'package:squiggle_flutter/tools/select_tool/polyline_handle.dart';
import 'package:squiggle_flutter/tools/select_tool/resize_handle.dart';

class HitTarget {}

class CanvasTarget extends HitTarget {}

class NodeTarget extends HitTarget {
  final Node node;

  NodeTarget({required this.node});
}

class ResizeHandleTarget extends HitTarget {
  final ResizeHandle handle;

  ResizeHandleTarget({required this.handle});
}

class PolylineHandleTarget extends HitTarget {
  final PolylineHandle handle;

  PolylineHandleTarget({required this.handle});
}
