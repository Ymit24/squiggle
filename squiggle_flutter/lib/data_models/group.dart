import 'json_helpers.dart';
import 'node.dart';

final class Group extends Node {
  const Group({
    required super.id,
    required super.origin,
    required this.children,
  });

  final List<Node> children;

  factory Group.fromJson(Map<String, dynamic> json) => Group(
    id: json['id'] as int,
    origin: offsetFromJson(json['origin'] as Map<String, dynamic>),
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
}
