import 'dart:ui';

import 'package:squiggle_flutter/models/node.dart';

class Group extends Node {
  Group({super.id, required this.children, required super.origin});

  List<Node> children;

  @override
  Rect bounds() => Node.boundsOfNodes(children);
}
