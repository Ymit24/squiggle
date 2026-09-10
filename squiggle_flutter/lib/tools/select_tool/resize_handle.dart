import 'dart:ui';

import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/tools/select_tool/helpers.dart';

class ResizeHandle {
  final Node node;
  final SelectionResizeHandle handle;
  final Rect geometry;

  ResizeHandle({
    required this.node,
    required this.handle,
    required this.geometry,
  });
}
