import 'package:collection/collection.dart';

import 'node.dart';

final class Group extends Node {
  const Group({
    required super.id,
    required super.originX,
    required super.originY,
    required this.children,
  });

  final List<Node> children;

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'] as int,
    originX: (json['originX'] as num).toDouble(),
    originY: (json['originY'] as num).toDouble(),
    children: [
      for (final child in json['children'] as List<dynamic>)
        Node.fromJson(child as Map<String, dynamic>),
    ],
  );

  @override
  Map<String, dynamic> toJson() => {
    ...baseJson('group'),
    'children': children.map((child) => child.toJson()).toList(),
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Group &&
          id == other.id &&
          originX == other.originX &&
          originY == other.originY &&
          const ListEquality<Node>().equals(children, other.children);

  @override
  int get hashCode => Object.hash(
    id,
    originX,
    originY,
    const ListEquality<Node>().hash(children),
  );
}
