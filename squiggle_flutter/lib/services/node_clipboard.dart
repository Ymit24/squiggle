import 'dart:convert';
import 'dart:typed_data';

import 'package:data_models/data_models.dart' as data;
import 'package:flutter/widgets.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

const _clipboardPrefix = 'squiggle-nodes:2:';

/// Offsets root [nodes] so their combined bounds center at [targetCenter].
List<T> repositionNodesToCenter<T extends Node>(
  List<T> nodes,
  Offset targetCenter,
) {
  if (nodes.isEmpty) return nodes;
  final offset = targetCenter - Node.localBoundsOfNodes(nodes).center;
  return [
    for (final node in nodes)
      node.copyWith(id: noId, origin: node.origin + offset) as T,
  ];
}

Future<String> encodeNodesForClipboard(
  List<Node> nodes,
  ImageRepository imageRepository,
) async => jsonEncode({
  'nodes': [for (final node in nodes) await _encodeNode(node, imageRepository)],
});

Future<List<Node>?> decodeNodesFromClipboard(
  String payload,
  ImageRepository imageRepository,
) async {
  try {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    final rawNodes = json['nodes'] as List<dynamic>?;
    if (rawNodes == null) return null;
    return [
      for (final raw in rawNodes)
        (await _decodeNode(
          Map<String, dynamic>.from(raw as Map),
          imageRepository,
        )).copyWith(id: noId),
    ];
  } on Object {
    return null;
  }
}

Future<void> copySelectedNodesToClipboard({
  required EditorContext context,
  required ImageRepository imageRepository,
}) async {
  final selectedIds = context.selection.selectedNodeIds;
  if (selectedIds.isEmpty) {
    return;
  }

  final selected = selectedIds.toSet();
  final nodes = context.document.nodes
      .where((node) => selected.contains(node.id))
      .toList();
  if (nodes.isEmpty) return;

  final payload = await encodeNodesForClipboard(nodes, imageRepository);
  await _writePlainText('$_clipboardPrefix$payload');
}

Future<bool> pasteNodesFromClipboard({
  required EditorContext context,
  required ImageRepository imageRepository,
}) async {
  final text = await _readPlainText();
  if (text == null || !text.startsWith(_clipboardPrefix)) {
    return false;
  }

  final nodes = await decodeNodesFromClipboard(
    text.substring(_clipboardPrefix.length),
    imageRepository,
  );
  if (nodes == null || nodes.isEmpty) {
    return false;
  }

  final center = context.worldCenterAtViewportCenter();
  if (center == null) {
    return false;
  }

  final pasted = repositionNodesToCenter(nodes, center);
  context.cancelInteraction();
  context.history.run('Paste', (transaction) {
    for (final node in pasted) {
      transaction.add(node);
    }
  });
  context.selection.setSelection(pasted.map((node) => node.id));
  return true;
}

Future<Map<String, dynamic>> _encodeNode(
  Node node,
  ImageRepository imageRepository,
) async {
  final json = Map<String, dynamic>.from(node.toDataModel().toJson());
  if (node is Group) {
    json['children'] = [
      for (final child in node.children)
        await _encodeNode(child, imageRepository),
    ];
  } else if (node case Feature(kind: FeatureKindImage(:final imageId))) {
    final bytes = await imageRepository.readPngBytes(imageId);
    if (bytes != null) {
      final content = Map<String, dynamic>.from(json['content'] as Map);
      content['pngBase64'] = base64Encode(bytes);
      json['content'] = content;
    }
  }
  return json;
}

Future<Node> _decodeNode(
  Map<String, dynamic> json,
  ImageRepository imageRepository,
) async {
  if (json['type'] == 'group') {
    json['children'] = [
      for (final child in json['children'] as List<dynamic>)
        (await _decodeNode(
          Map<String, dynamic>.from(child as Map),
          imageRepository,
        )).toDataModel().toJson(),
    ];
  } else if (json['type'] == 'feature') {
    final content = Map<String, dynamic>.from(json['content'] as Map);
    final encodedPng = content.remove('pngBase64') as String?;
    if (content['type'] == 'image' && encodedPng != null) {
      final imported = await imageRepository.importPngBytes(
        Uint8List.fromList(base64Decode(encodedPng)),
      );
      if (imported == null) throw const FormatException('Invalid image data');
      content['imageId'] = imported.imageId;
    }
    json['content'] = content;
  }
  return Node.fromDataModel(data.Node.fromJson(json));
}

Future<String?> readClipboardPlainText() => _readPlainText();

bool isSquiggleNodesClipboardText(String text) =>
    text.startsWith(_clipboardPrefix);

Future<void> _writePlainText(String text) async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    return;
  }

  final item = DataWriterItem(suggestedName: 'squiggle-nodes');
  item.add(Formats.plainText(text));
  await clipboard.write([item]);
}

Future<String?> _readPlainText() async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    return null;
  }

  final reader = await clipboard.read();
  for (final item in reader.items) {
    if (item.canProvide(Formats.plainText)) {
      return item.readValue(Formats.plainText);
    }
  }
  return null;
}
