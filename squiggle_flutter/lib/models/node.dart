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

  /// TODO: comment
  NodeId id;

  /// Relative to parent node.
  Offset _origin;
  Offset get origin => _origin;

  final Set<NodeId> _boundFeatureIds = {};
  late final Set<NodeId> boundFeatureIds = UnmodifiableSetView(
    _boundFeatureIds,
  );

  void addBoundFeature(NodeId id) => _boundFeatureIds.add(id);
  void removeBoundFeature(NodeId id) => _boundFeatureIds.remove(id);
  void clearBoundFeatures() => _boundFeatureIds.clear();

  Offset get globalOrigin => origin + (parent?.globalOrigin ?? Offset.zero);

  // Keep the public argument named origin while the field remains private.
  // ignore: prefer_initializing_formals
  Node({this.id = noId, required Offset origin}) : _origin = origin;

  void editGeometry(void Function(NodeGeometryEdit edit) change) {
    void apply() {
      final edit = createGeometryEdit();
      change(edit);
      commitGeometryEdit(edit);
    }

    final owner = document;
    if (owner == null) {
      apply();
    } else {
      owner.editGeometry(this, apply);
    }
  }

  NodeGeometryEdit createGeometryEdit() => NodeGeometryEdit(_origin);

  void commitGeometryEdit(NodeGeometryEdit edit) => _origin = edit.origin;

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

  void resize(Rect bounds);

  Offset center() => localBounds().center;
}

class NodeGeometryEdit {
  NodeGeometryEdit(this.origin, {this.size});

  Offset origin;
  Size? size;
}
