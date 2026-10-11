import 'package:data_models/src/feature.dart';
import 'package:data_models/src/group.dart';

abstract class Node {
  const Node({
    required this.id,
    required this.originX,
    required this.originY,
    required this.localRotationAngle,
  });

  factory Node.fromJson(Map<String, dynamic> json) => switch (json['type']) {
    'feature' => Feature.fromJson(json),
    'group' => Group.fromJson(json),
    _ => throw FormatException('Unknown node type: ${json['type']}'),
  };

  final int id;
  final double originX;
  final double originY;
  final double localRotationAngle;

  Map<String, dynamic> toJson();

  Map<String, dynamic> baseJson(String type) => {
    'type': type,
    'id': id,
    'originX': originX,
    'originY': originY,
    'localRotationAngle': localRotationAngle,
  };
}
