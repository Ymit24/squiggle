import 'dart:ui';
import 'dart:collection';

import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

part 'node_container.dart';

abstract class Node {
  NodeContainer? _parent;

  /// Direct owner; null while detached. Maintained by container operations.
  NodeContainer? get parent => _parent;

  Document? get document => parent?.document;

  factory Node.fromDataModel(data.Node raw) => switch (raw) {
    data.Feature feature => Feature.fromDataModel(feature),
    data.Group group => Group.fromDataModel(group),
    _ => throw FormatException('Unknown node type: ${raw.runtimeType}'),
  };

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
  NodeId id;

  /// Relative to parent node.
  Offset origin;

  Node({this.id = noId, required this.origin});

  /// TODO: comment
  Rect bounds();

  Node copyWith({NodeId? id, Offset? origin});

  data.Node toDataModel();

  void restoreFromDataModel(data.Node raw);

  void paint(Canvas canvas, ImageRepository imageRepository);

  bool intersectsRect(Rect rect);

  void resize(Rect bounds);
}
