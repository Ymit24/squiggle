import 'dart:convert';

import 'package:data_models/src/document_session.dart';
import 'package:data_models/src/node.dart';

const dataModelFormatVersion = 2;

final class Document {
  const Document({
    this.name = 'Untitled',
    this.nodes = const [],
    this.session = const DocumentSession(),
  });

  factory Document.fromJson(Map<String, dynamic> json) {
    if (json['version'] != dataModelFormatVersion) {
      throw FormatException('Unsupported document version: ${json['version']}');
    }

    final nodes = [
      for (final node in json['nodes'] as List<dynamic>)
        Node.fromJson(node as Map<String, dynamic>),
    ];

    return Document(
      name: json['name'] as String? ?? 'Untitled',
      nodes: nodes,
      session: json['session'] is Map<String, dynamic>
          ? DocumentSession.fromJson(json['session'] as Map<String, dynamic>)
          : const DocumentSession(),
    );
  }

  factory Document.decode(String value) =>
      Document.fromJson(jsonDecode(value) as Map<String, dynamic>);

  final String name;
  final List<Node> nodes;
  final DocumentSession session;

  Map<String, dynamic> toJson() => {
    'version': dataModelFormatVersion,
    'name': name,
    'nodes': nodes.map((node) => node.toJson()).toList(),
    'session': session.toJson(),
  };

  String encode() => jsonEncode(toJson());
}
