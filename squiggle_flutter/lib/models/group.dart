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
  Rect bounds() => Node.boundsOfNodes(children);

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
