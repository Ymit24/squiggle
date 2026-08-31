import 'dart:ui';

import 'feature.dart';
import 'group.dart';
import 'json_helpers.dart';

abstract class Node {
  const Node({required this.id, required this.origin});

  final int id;
  final Offset origin;

  Map<String, dynamic> toJson();

  factory Node.fromJson(Map<String, dynamic> json) => switch (json['type']) {
    'feature' => Feature.fromJson(json),
    'group' => Group.fromJson(json),
    _ => throw FormatException('Unknown node type: ${json['type']}'),
  };

  Map<String, dynamic> baseJson(String type) => {
    'type': type,
    'id': id,
    'origin': offsetToJson(origin),
  };
}
