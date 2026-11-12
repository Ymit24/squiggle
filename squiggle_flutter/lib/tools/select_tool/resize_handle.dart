import 'dart:ui';

import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/tools/select_tool/selection_resize_handle.dart';

class ResizeHandle {
  ResizeHandle({
    required this.node,
    required this.handle,
    required this.geometry,
  });
  final Node node;
  final SelectionResizeHandle handle;
  final Rect geometry;
}
