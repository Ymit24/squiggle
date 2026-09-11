import 'feature.dart';
import 'group.dart';

abstract class Node {
  const Node({required this.id, required this.originX, required this.originY});

  final int id;
  final double originX;
  final double originY;

  Map<String, dynamic> toJson();

  factory Node.fromJson(Map<String, dynamic> json) => switch (json['type']) {
    'feature' => Feature.fromJson(json),
    'group' => Group.fromJson(json),
    _ => throw FormatException('Unknown node type: ${json['type']}'),
  };

  Map<String, dynamic> baseJson(String type) => {
    'type': type,
    'id': id,
    'originX': originX,
    'originY': originY,
  };
}
