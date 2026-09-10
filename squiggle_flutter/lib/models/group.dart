import 'dart:ui';

import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

class Group extends Node with NodeContainer {
  Group({super.id, required List<Node> children, required super.origin}) {
    for (final child in children) {
      insert(child);
    }
  }

  factory Group.fromDataModel(data.Group raw) => Group(
    id: NodeId.newId(raw.id),
    origin: Offset(raw.originX, raw.originY),
    children: raw.children.map(Node.fromDataModel).toList(),
  );

  @override
  Rect localBounds() => Node.boundsOfNodes(children).shift(origin);

  @override
  Group copyWith({NodeId? id, Offset? origin}) => Group(
    id: id ?? this.id,
    origin: origin ?? this.origin,
    children: children
        .map((child) => child.copyWith(id: id == noId ? noId : null))
        .toList(),
  );

  @override
  data.Group toDataModel() => data.Group(
    id: id.value,
    originX: origin.dx,
    originY: origin.dy,
    children: children.map((child) => child.toDataModel()).toList(),
  );

  @override
  void restoreFromDataModel(data.Node raw) {
    if (raw is! data.Group || raw.id != id.value) {
      throw ArgumentError.value(raw, 'raw', 'Group snapshot does not match');
    }
    final restored = raw.children.map(Node.fromDataModel).toList();
    removeAll(children.map((child) => child.id));
    for (final child in restored) {
      insert(child);
    }
    origin = Offset(raw.originX, raw.originY);
  }

  @override
  bool intersectsRect(Rect rect) {
    return localBounds().overlaps(rect);
  }

  @override
  bool hitTest(Offset worldPoint) {
    return localBounds().contains(worldPoint);
  }

  @override
  void paint(Canvas canvas, ImageRepository imageRepository) {
    print("D: painting group at ${origin}");
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    for (final child in children) {
      child.paint(canvas, imageRepository);
    }
    canvas.restore();
  }

  @override
  void resize(Rect bounds) {}
}
