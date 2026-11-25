import 'dart:collection';
import 'dart:ui';

import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

part 'node_container.dart';

abstract class Node {
  factory Node.fromDataModel(data.Node raw) => switch (raw) {
    data.Feature feature => Feature.fromDataModel(feature),
    data.Group group => Group.fromDataModel(group),
    _ => throw FormatException('Unknown node type: ${raw.runtimeType}'),
  };

  Node({this.id = noId, required this.origin});
  NodeContainer? _parent;

  NodeId id;

  /// Relative to parent node.
  Offset origin;

  /// Direct owner; null while detached. Maintained by container operations.
  NodeContainer? get parent => _parent;

  Document? get document => parent?.document;

  Offset get globalOrigin => origin + (parent?.globalOrigin ?? Offset.zero);

  /// This node followed by all of its descendants, depth first.
  Iterable<Node> get subtree sync* {
    yield this;
    if (this case final NodeContainer container) {
      for (final child in container.children) {
        yield* child.subtree;
      }
    }
  }

  /// Other nodes this node refers to by id.
  Iterable<NodeId> get references => const [];

  /// Returns the union of [nodes] bounds in local world space.
  static Rect localBoundsOfNodes(List<Node> nodes) {
    if (nodes.isEmpty) {
      return Rect.zero;
    }
    var rect = nodes.first.localBounds();
    for (final node in nodes.skip(1)) {
      rect = rect.expandToInclude(node.localBounds());
    }
    return rect;
  }

  Rect globalBounds() {
    return localBounds().shift(parent?.globalOrigin ?? Offset.zero);
  }

  Rect localBounds();

  Node copyWith({NodeId? id, Offset? origin});

  data.Node toDataModel();

  void restoreFromDataModel(data.Node raw);

  void paint(Canvas canvas, ImageRepository imageRepository);

  bool intersectsRect(Rect rect);

  bool hitTest(Offset worldPoint);

  /// Resizes this node to [bounds]. Nodes whose size follows their contents
  /// may end up near [bounds] rather than exactly on it.
  void resize(Rect bounds);

  Offset center() => localBounds().center;

  /// Where a ray from this node's center toward [globalPoint] crosses its
  /// outline, in global space.
  Offset outlinePointToward(Offset globalPoint) =>
      rectOutlinePointToward(globalBounds(), globalPoint);

  /// Called, as part of the same edit, just before the nodes in [ids] that
  /// this node refers to are removed.
  void referencesRemoved(Set<NodeId> ids) {}
}
