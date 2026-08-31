import 'dart:ui';

import 'feature_kind.dart';
import 'json_helpers.dart';
import 'node.dart';

final class Feature extends Node {
  const Feature({
    required super.id,
    required super.origin,
    required this.size,
    required this.kind,
  });

  final Size size;
  final FeatureKind kind;

  factory Feature.fromJson(Map<String, dynamic> json) => Feature(
    id: json['id'] as int,
    origin: offsetFromJson(json['origin'] as Map<String, dynamic>),
    size: sizeFromJson(json['size'] as Map<String, dynamic>),
    kind: FeatureKind.fromJson(json['kind'] as Map<String, dynamic>),
  );

  @override
  Map<String, dynamic> toJson() => {
    ...baseJson('feature'),
    'size': sizeToJson(size),
    'kind': kind.toJson(),
  };
}
