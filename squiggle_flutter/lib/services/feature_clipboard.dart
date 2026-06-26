import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:squiggle_flutter/models/commands/command.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/viewport_repository.dart';

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

  final payload = await _encodeFeatures(features, imageRepository);
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

  final features = await _decodeFeatures(
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

Future<String> _encodeFeatures(
  List<Feature> features,
  ImageRepository imageRepository,
) async {
  final encoded = <Map<String, dynamic>>[];
  for (final feature in features) {
    encoded.add(await _encodeFeature(feature, imageRepository));
  }
  return jsonEncode({'features': encoded});
}

Future<Map<String, dynamic>> _encodeFeature(
  Feature feature,
  ImageRepository imageRepository,
) async {
  return {
    'origin': _encodeOffset(feature.origin),
    'size': _encodeSize(feature.size),
    'kind': await _encodeKind(feature.kind, imageRepository),
  };
}

Future<Map<String, dynamic>> _encodeKind(
  FeatureKind kind,
  ImageRepository imageRepository,
) async {
  return switch (kind) {
    FeatureKindRectangle() => {
      'type': 'rectangle',
      'strokeColor': kind.strokeColor.toARGB32(),
      'fillColor': kind.fillColor.toARGB32(),
      'strokeWidth': kind.strokeWidth,
    },
    FeatureKindCircle() => {
      'type': 'circle',
      'strokeColor': kind.strokeColor.toARGB32(),
      'fillColor': kind.fillColor.toARGB32(),
      'strokeWidth': kind.strokeWidth,
    },
    FeatureKindText() => {
      'type': 'text',
      'contents': kind.contents,
      'fontSize': kind.fontSize,
      'horizontalAlignment': kind.horizontalAlignment.name,
      'verticalAlignment': kind.verticalAlignment.name,
      'strokeColor': kind.strokeColor.toARGB32(),
      'fillColor': kind.fillColor.toARGB32(),
      'strokeWidth': kind.strokeWidth,
    },
    FeatureKindPolyline() => {
      'type': 'polyline',
      'localPoints': [
        for (final point in kind.localPoints) _encodeOffset(point),
      ],
      'strokeColor': kind.strokeColor.toARGB32(),
      'fillColor': kind.fillColor.toARGB32(),
      'strokeWidth': kind.strokeWidth,
    },
    FeatureKindImage() => {
      'type': 'image',
      'strokeColor': kind.strokeColor.toARGB32(),
      'strokeWidth': kind.strokeWidth,
      'pngBase64': base64Encode(
        await imageRepository.readPngBytes(kind.imageId) ?? Uint8List(0),
      ),
    },
  };
}

Future<List<Feature>?> _decodeFeatures(
  String payload,
  ImageRepository imageRepository,
) async {
  try {
    final json = jsonDecode(payload) as Map<String, dynamic>;
    final rawFeatures = json['features'] as List<dynamic>?;
    if (rawFeatures == null) {
      return null;
    }

    final features = <Feature>[];
    for (final raw in rawFeatures) {
      final feature = await _decodeFeature(
        raw as Map<String, dynamic>,
        imageRepository,
      );
      if (feature != null) {
        features.add(feature);
      }
    }
    return features;
  } on Object {
    return null;
  }
}

Future<Feature?> _decodeFeature(
  Map<String, dynamic> json,
  ImageRepository imageRepository,
) async {
  final kind = await _decodeKind(
    json['kind'] as Map<String, dynamic>,
    imageRepository,
  );
  if (kind == null) {
    return null;
  }

  return Feature(
    origin: _decodeOffset(json['origin'] as Map<String, dynamic>),
    size: _decodeSize(json['size'] as Map<String, dynamic>),
    kind: kind,
  );
}

Future<FeatureKind?> _decodeKind(
  Map<String, dynamic> json,
  ImageRepository imageRepository,
) async {
  return switch (json['type'] as String?) {
    'rectangle' => FeatureKindRectangle(
      strokeColor: Color(json['strokeColor'] as int),
      fillColor: Color(json['fillColor'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
    ),
    'circle' => FeatureKindCircle(
      strokeColor: Color(json['strokeColor'] as int),
      fillColor: Color(json['fillColor'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
    ),
    'text' => FeatureKindText(
      json['contents'] as String,
      fontSize: (json['fontSize'] as num).toDouble(),
      horizontalAlignment: TextHorizontalAlignment.values.byName(
        json['horizontalAlignment'] as String,
      ),
      verticalAlignment: TextVerticalAlignment.values.byName(
        json['verticalAlignment'] as String,
      ),
      strokeColor: Color(json['strokeColor'] as int),
      fillColor: Color(json['fillColor'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
    ),
    'polyline' => FeatureKindPolyline(
      [
        for (final point in json['localPoints'] as List<dynamic>)
          _decodeOffset(point as Map<String, dynamic>),
      ],
      strokeColor: Color(json['strokeColor'] as int),
      fillColor: Color(json['fillColor'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
    ),
    'image' => _decodeImageKind(json, imageRepository),
    _ => null,
  };
}

Future<FeatureKindImage?> _decodeImageKind(
  Map<String, dynamic> json,
  ImageRepository imageRepository,
) async {
  final pngBase64 = json['pngBase64'] as String?;
  if (pngBase64 == null || pngBase64.isEmpty) {
    return null;
  }

  final imported = await imageRepository.importPngBytes(base64Decode(pngBase64));
  if (imported == null) {
    return null;
  }

  return FeatureKindImage(
    imported.imageId,
    strokeColor: Color(json['strokeColor'] as int),
    strokeWidth: (json['strokeWidth'] as num).toDouble(),
  );
}

Map<String, dynamic> _encodeOffset(Offset offset) => {
  'x': offset.dx,
  'y': offset.dy,
};

Offset _decodeOffset(Map<String, dynamic> json) =>
    Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble());

Map<String, dynamic> _encodeSize(Size size) => {
  'width': size.width,
  'height': size.height,
};

Size _decodeSize(Map<String, dynamic> json) => Size(
  (json['width'] as num).toDouble(),
  (json['height'] as num).toDouble(),
);

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
