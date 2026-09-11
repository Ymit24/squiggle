import 'package:collection/collection.dart';

import 'package:data_models/src/node.dart';

final class Feature extends Node {
  const Feature({
    required super.id,
    required super.originX,
    required super.originY,
    required this.width,
    required this.height,
    required this.content,
  });

  final double width;
  final double height;
  final Map<String, dynamic> content;

  factory Feature.fromJson(Map<String, dynamic> json) => Feature(
    id: json['id'] as int,
    originX: (json['originX'] as num).toDouble(),
    originY: (json['originY'] as num).toDouble(),
    width: (json['width'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    content: Map<String, dynamic>.from(json['content'] as Map),
  );

  @override
  Map<String, dynamic> toJson() => {
    ...baseJson('feature'),
    'width': width,
    'height': height,
    'content': content,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Feature &&
          id == other.id &&
          originX == other.originX &&
          originY == other.originY &&
          width == other.width &&
          height == other.height &&
          const DeepCollectionEquality().equals(content, other.content);

  @override
  int get hashCode => Object.hash(
    id,
    originX,
    originY,
    width,
    height,
    const DeepCollectionEquality().hash(content),
  );
}
