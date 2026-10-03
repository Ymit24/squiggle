import 'package:squiggle_flutter/models/node.dart';

import 'package:squiggle_flutter/tools/select_tool/polyline_handle.dart';
import 'package:squiggle_flutter/tools/select_tool/resize_handle.dart';

class HitTarget {}

class CanvasTarget extends HitTarget {}

class NodeTarget extends HitTarget {
  NodeTarget({required this.node});
  final Node node;
}

class ResizeHandleTarget extends HitTarget {
  ResizeHandleTarget({required this.handle});
  final ResizeHandle handle;
}

class PolylineHandleTarget extends HitTarget {
  PolylineHandleTarget({required this.handle});
  final PolylineHandle handle;
}
