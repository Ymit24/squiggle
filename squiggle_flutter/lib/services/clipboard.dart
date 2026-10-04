import 'dart:convert';

import 'package:data_models/data_models.dart' as data;
import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/models/node_layout.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:super_clipboard/super_clipboard.dart';

const _clipboardFormatPrefix = 'squiggle-nodes:';
const _clipboardPrefix = '${_clipboardFormatPrefix}3:';

Future<bool> copySelectedNodesToClipboard({
  required EditorContext context,
  required ImageRepository imageRepository,
}) async {
  final selectedIds = context.selection.selectedNodeIds.toSet();
  final nodes = context.document.nodes
      .where((node) => selectedIds.contains(node.id))
      .toList();
  if (nodes.isEmpty) return false;

  final payload = await encodeNodesForClipboard(nodes, imageRepository);
  return _writeClipboardPlainText('$_clipboardPrefix$payload');
}

Future<void> cutSelectedNodesToClipboard({
  required EditorContext context,
  required ImageRepository imageRepository,
}) async {
  final selectedIds = context.selection.selectedNodeIds.toSet();
  final copied = await copySelectedNodesToClipboard(
    context: context,
    imageRepository: imageRepository,
  );
  if (!copied) return;

  context.cancelInteraction();
  context.history.run('Cut', (transaction) {
    transaction.removeAll(selectedIds);
  });
  context.selection.setSelection(
    context.selection.selectedNodeIds.where((id) => !selectedIds.contains(id)),
  );
}

Future<void> pasteFromClipboard({
  required EditorContext context,
  required ImageRepository imageRepository,
}) async {
  final center = context.worldCenterAtViewportCenter();
  if (center == null) return;

  final nodes = await _readNodesForPaste(
    context: context,
    imageRepository: imageRepository,
  );
  if (nodes.isEmpty) return;

  centerNodesAt(nodes, center);
  context.cancelInteraction();
  context.history.run('Paste', (transaction) {
    for (final node in nodes) {
      transaction.add(node);
    }
  });
  context.selection.setSelection(nodes.map((node) => node.id));
}

/// The payload includes each referenced PNG once, independent of local storage.
Future<String> encodeNodesForClipboard(
  List<Node> nodes,
  ImageRepository imageRepository,
) async {
  final images = <String, String>{};
  final imageIds = _imagesIn(nodes).map((image) => image.imageId).toSet();

  for (final imageId in imageIds) {
    final bytes = await imageRepository.readPngBytes(imageId);
    if (bytes == null) {
      throw StateError('Missing clipboard image: $imageId');
    }
    images[imageId] = base64Encode(bytes);
  }

  return jsonEncode({
    'nodes': [for (final node in nodes) node.toDataModel().toJson()],
    'images': images,
  });
}

/// Returns detached nodes with fresh identities, or null for an invalid payload.
Future<List<Node>?> decodeNodesFromClipboard(
  String payload,
  ImageRepository imageRepository,
) async {
  try {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    final nodes = [
      for (final raw in json['nodes'] as List<dynamic>)
        Node.fromDataModel(
          data.Node.fromJson(Map<String, dynamic>.from(raw as Map)),
        ),
    ];
    final images = Map<String, dynamic>.from(json['images'] as Map);
    await _importImageAttachments(nodes, images, imageRepository);

    // Group.copyWith also resets the IDs of its descendants.
    return [for (final node in nodes) node.copyWith(id: noId)];
  } on Object {
    return null;
  }
}

Future<List<Node>> _readNodesForPaste({
  required EditorContext context,
  required ImageRepository imageRepository,
}) async {
  final nodes = await _nodesFromClipboardText(
    await _readClipboardPlainText(),
    context: context,
    imageRepository: imageRepository,
  );
  if (nodes != null && nodes.isNotEmpty) return nodes;

  return _readImageForPaste(context: context, imageRepository: imageRepository);
}

Future<List<Node>?> _nodesFromClipboardText(
  String? text, {
  required EditorContext context,
  required ImageRepository imageRepository,
}) async {
  if (text == null) return null;

  if (text.startsWith(_clipboardPrefix)) {
    return decodeNodesFromClipboard(
      text.substring(_clipboardPrefix.length),
      imageRepository,
    );
  }

  // Unsupported Squiggle payloads must not become canvas text.
  if (text.startsWith(_clipboardFormatPrefix) || text.trim().isEmpty) {
    return null;
  }

  return [
    newTextFeatureAt(
      Offset.zero,
      text,
      configureKind: context.brushes.active.applyTo,
    ),
  ];
}

Future<List<Node>> _readImageForPaste({
  required EditorContext context,
  required ImageRepository imageRepository,
}) async {
  final imported = await imageRepository.importFromClipboard();
  if (imported == null) return [];

  final feature = Feature(
    origin: Offset.zero,
    size: clampImageWorldSize(imported.intrinsicSize),
    kind: FeatureKindImage(imported.imageId),
  );
  context.brushes.active.applyTo(feature.kind);
  return [feature];
}

/// Only mutates image references on newly decoded nodes.
Future<void> _importImageAttachments(
  List<Node> nodes,
  Map<String, dynamic> images,
  ImageRepository imageRepository,
) async {
  final importedIds = <String, String>{};

  for (final image in _imagesIn(nodes)) {
    final originalId = image.imageId;
    final importedId = importedIds[originalId];
    if (importedId != null) {
      image.imageId = importedId;
      continue;
    }

    final encoded = images[originalId] as String?;
    if (encoded == null) {
      throw FormatException('Missing image attachment: $originalId');
    }

    final imported = await imageRepository.importPngBytes(
      base64Decode(encoded),
    );
    if (imported == null) {
      throw const FormatException('Invalid image attachment');
    }

    importedIds[originalId] = imported.imageId;
    image.imageId = imported.imageId;
  }
}

Iterable<FeatureKindImage> _imagesIn(Iterable<Node> nodes) sync* {
  for (final node in nodes) {
    if (node is Group) {
      yield* _imagesIn(node.children);
    } else if (node case Feature(kind: FeatureKindImage image)) {
      yield image;
    }
  }
}

Future<bool> _writeClipboardPlainText(String text) async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) return false;

  final item = DataWriterItem(suggestedName: 'squiggle-nodes');
  item.add(Formats.plainText(text));
  await clipboard.write([item]);
  return true;
}

Future<String?> _readClipboardPlainText() async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) return null;

  final reader = await clipboard.read();
  for (final item in reader.items) {
    if (item.canProvide(Formats.plainText)) {
      return item.readValue(Formats.plainText);
    }
  }
  return null;
}
