import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
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

  Node({
    this.id = noId,
    required this.origin,
    required this.localRotationAngle,
  });
  NodeContainer? _parent;

  NodeId id;

  /// Relative to parent node.
  Offset origin;

  /// Angle in degrees relative to parent node.
  double localRotationAngle;

  /// Direct owner; null while detached. Maintained by container operations.
  NodeContainer? get parent => _parent;

  Document? get document => parent?.document;

  Offset get globalOrigin => origin + (parent?.globalOrigin ?? Offset.zero);

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

  /// Returns an axis-aligned rectangle enclosing this node's rotated bounds.
  ///
  /// The rectangle remains in the same coordinate space as [localBounds].
  Rect screenBounds() {
    final bounds = localBounds();
    final cosAngle = math.cos(localRotationAngle * math.pi / 180).abs();
    final sinAngle = math.sin(localRotationAngle * math.pi / 180).abs();
    final width = bounds.width * cosAngle + bounds.height * sinAngle;
    final height = bounds.width * sinAngle + bounds.height * cosAngle;
    return Rect.fromCenter(center: bounds.center, width: width, height: height);
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
