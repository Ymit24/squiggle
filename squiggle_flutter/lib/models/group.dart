import 'dart:ui';

import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

class Group extends Node {
  Group({super.id, required this.children, required super.origin});

  List<Node> children;

  @override
  Rect bounds() => Node.boundsOfNodes(children);

  @override
  Node copyWith({FeatureId? id, Offset? origin}) {
    // TODO: implement copyWith
    throw UnimplementedError();
  }

  @override
  bool intersectsRect(Rect rect) {
    // TODO: implement intersectsRect
    throw UnimplementedError();
  }

  @override
  void paint(Canvas canvas, ImageRepository imageRepository) {
    // TODO: implement paint
  }

  @override
  void resize(Rect bounds) {}
}
