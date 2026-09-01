import 'dart:convert';

import 'package:data_models/data_models.dart' as data;
import 'package:flutter/widgets.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

const _clipboardPrefix = 'squiggle-features:1:';

/// Offsets [features] so their combined bounds center at [targetCenter].
List<Feature> repositionFeaturesToCenter(
  List<Feature> features,
  Offset targetCenter,
) {
  if (features.isEmpty) {
    return features;
  }
  final offset = targetCenter - Node.boundsOfNodes(features).center;
  return [
    for (final feature in features)
      feature.copyWith(id: noId, origin: feature.origin + offset),
  ];
}

Future<void> copySelectedFeaturesToClipboard({
  required EditorContext context,
  required ImageRepository imageRepository,
}) async {
  final selectedIds = context.selection.selectedFeatures;
  if (selectedIds.isEmpty) {
    return;
  }

  final features = <Feature>[];
  for (final id in selectedIds) {
    final feature = context.document.featureById(id);
    if (feature != null) {
      features.add(feature.copyWith());
    }
  }
  if (features.isEmpty) {
    return;
  }

  final payload = jsonEncode({
    'features': [
      for (final feature in features) feature.toDataModel().toJson(),
    ],
  });
  await _writePlainText('$_clipboardPrefix$payload');
}

Future<bool> pasteFeaturesFromClipboard({
  required EditorContext context,
  required ImageRepository imageRepository,
}) async {
  final text = await _readPlainText();
  if (text == null || !text.startsWith(_clipboardPrefix)) {
    return false;
  }

  final features = _decodeFeatures(text.substring(_clipboardPrefix.length));
  if (features == null || features.isEmpty) {
    return false;
  }

  final center = context.worldCenterAtViewportCenter();
  if (center == null) {
    return false;
  }

  final pasted = repositionFeaturesToCenter(features, center);
  context.execute(AddFeaturesCommand(pasted));
  return true;
}

List<Feature>? _decodeFeatures(String payload) {
  try {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    final rawFeatures = json['features'] as List<dynamic>?;
    if (rawFeatures == null) {
      return null;
    }

    return [
      for (final raw in rawFeatures)
        Feature.fromDataModel(
          data.Feature.fromJson(raw as Map<String, dynamic>),
        ),
    ];
  } on Object {
    return null;
  }
}

Future<String?> readClipboardPlainText() => _readPlainText();

bool isSquiggleFeaturesClipboardText(String text) =>
    text.startsWith(_clipboardPrefix);

Future<void> _writePlainText(String text) async {
  final clipboard = SystemClipboard.instance;
  if (clipboard == null) {
    return;
  }

  final item = DataWriterItem(suggestedName: 'squiggle-features');
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
