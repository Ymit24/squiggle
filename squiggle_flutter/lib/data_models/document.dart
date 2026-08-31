import 'dart:convert';

import 'node.dart';

const dataModelFormatVersion = 1;

final class Document {
  const Document({
    this.name = 'Untitled',
    this.nextId = 1,
    this.nodes = const [],
  });

  final String name;
  final int nextId;
  final List<Node> nodes;

  factory Document.fromJson(Map<String, dynamic> json) {
    if (json['version'] != dataModelFormatVersion) {
      throw FormatException('Unsupported document version: ${json['version']}');
    }
    return Document(
      name: json['name'] as String? ?? 'Untitled',
      nextId: json['nextId'] as int? ?? 1,
      nodes: [
        for (final node in json['nodes'] as List<dynamic>)
          Node.fromJson(node as Map<String, dynamic>),
      ],
    );
  }

  Map<String, dynamic> toJson() => {
    'version': dataModelFormatVersion,
    'name': name,
    'nextId': nextId,
    'nodes': nodes.map((node) => node.toJson()).toList(),
  };

  String encode() => jsonEncode(toJson());

  factory Document.decode(String value) =>
      Document.fromJson(jsonDecode(value) as Map<String, dynamic>);
}
