import 'package:flutter/widgets.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:squiggle_flutter/models/commands/command.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/viewport_repository.dart';
import 'package:squiggle_flutter/services/document_codec.dart';

const _clipboardPrefix = 'squiggle-features:1:';

/// Union of [features] bounds in world space.
Rect boundsOfFeatures(List<Feature> features) {
  if (features.isEmpty) {
    return Rect.zero;
  }
  var rect = features.first.bounds();
  for (final feature in features.skip(1)) {
    rect = rect.expandToInclude(feature.bounds());
  }
  return rect;
}

/// Offsets [features] so their combined bounds center at [targetCenter].
List<Feature> repositionFeaturesToCenter(
  List<Feature> features,
  Offset targetCenter,
) {
  if (features.isEmpty) {
    return features;
  }
  final offset = targetCenter - boundsOfFeatures(features).center;
  return [
    for (final feature in features)
      feature.copyWith(id: noId, origin: feature.origin + offset),
  ];
}

Future<void> copySelectedFeaturesToClipboard({
  required DocumentRepository documentRepository,
  required SelectionRepository selectionRepository,
  required ImageRepository imageRepository,
}) async {
  final selectedIds = selectionRepository.selectedFeatures;
  if (selectedIds.isEmpty) {
    return;
  }

  final features = <Feature>[];
  for (final id in selectedIds) {
    final feature = documentRepository.document.featureById(id);
    if (feature != null) {
      features.add(feature.copyWith());
    }
  }
  if (features.isEmpty) {
    return;
  }

  final payload = await encodeFeaturesForClipboard(features, imageRepository);
  await _writePlainText('$_clipboardPrefix$payload');
}

Future<bool> pasteFeaturesFromClipboard({
  required DocumentRepository documentRepository,
  required ViewportRepository viewportRepository,
  required ImageRepository imageRepository,
}) async {
  final text = await _readPlainText();
  if (text == null || !text.startsWith(_clipboardPrefix)) {
    return false;
  }

  final features = await decodeFeaturesFromClipboard(
    text.substring(_clipboardPrefix.length),
    imageRepository,
  );
  if (features == null || features.isEmpty) {
    return false;
  }

  final center = viewportRepository.worldCenterAtViewportCenter();
  if (center == null) {
    return false;
  }

  final pasted = repositionFeaturesToCenter(features, center);
  documentRepository.executeCommand(AddFeaturesCommand(pasted));
  return true;
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
