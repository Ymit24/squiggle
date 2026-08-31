import 'dart:ui';

import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

abstract class Node {
  /// Returns the union of [nodes] bounds in world space.
  static Rect boundsOfNodes(List<Node> nodes) {
    if (nodes.isEmpty) {
      return Rect.zero;
    }
    var rect = nodes.first.bounds();
    for (final node in nodes.skip(1)) {
      rect = rect.expandToInclude(node.bounds());
    }
    return rect;
  }

  /// TODO: comment
  FeatureId id;

  /// Relative to parent node.
  Offset origin;

  Node({this.id = noId, required this.origin});

  /// TODO: comment
  Rect bounds();

  Node copyWith({FeatureId? id, Offset? origin});

  void paint(Canvas canvas, ImageRepository imageRepository);

  bool intersectsRect(Rect rect);
}
