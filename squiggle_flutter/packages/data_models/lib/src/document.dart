import 'dart:convert';

import 'node.dart';

const dataModelFormatVersion = 1;

final class Document {
  const Document({this.name = 'Untitled', this.nodes = const []});

  final String name;
  final List<Node> nodes;

  factory Document.fromJson(Map<String, dynamic> json) {
    if (json['version'] != dataModelFormatVersion) {
      throw FormatException('Unsupported document version: ${json['version']}');
    }

    final nodes = [
      for (final node in json['nodes'] as List<dynamic>)
        Node.fromJson(node as Map<String, dynamic>),
    ];

    return Document(name: json['name'] as String? ?? 'Untitled', nodes: nodes);
  }

  Map<String, dynamic> toJson() => {
    'version': dataModelFormatVersion,
    'name': name,
    'nodes': nodes.map((node) => node.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  factory Document.decode(String value) =>
      Document.fromJson(jsonDecode(value) as Map<String, dynamic>);
}
