import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

const documentFormatVersion = 1;

enum FeaturePersistenceMode {
  clipboard,
  document,
}

Future<String> encodeDocument(
  Document document,
  ImageRepository imageRepository,
) async {
  final encoded = <Map<String, dynamic>>[];
  for (final feature in document.features) {
    encoded.add(
      await encodeFeature(
        feature,
        imageRepository,
        mode: FeaturePersistenceMode.document,
      ),
    );
  }

  return jsonEncode({
    'version': documentFormatVersion,
    'nextId': document.nextId.value,
    'features': encoded,
  });
}

Document? decodeDocument(String json) {
  try {
    final map = jsonDecode(json) as Map<String, dynamic>;
    if (map['version'] != documentFormatVersion) {
      return null;
    }

    final nextIdValue = map['nextId'] as int?;
    if (nextIdValue == null) {
      return null;
    }

    final rawFeatures = map['features'] as List<dynamic>?;
    if (rawFeatures == null) {
      return null;
    }

    final features = <Feature>[];
    for (final raw in rawFeatures) {
      final feature = decodeFeature(
        raw as Map<String, dynamic>,
        mode: FeaturePersistenceMode.document,
      );
      if (feature == null) {
        return null;
      }
      features.add(feature);
    }

    final document = Document(nextId: FeatureId.newId(nextIdValue));
    document.features.addAll(features);
    return document;
  } on Object {
    return null;
  }
}

Future<String> encodeFeaturesForClipboard(
  List<Feature> features,
  ImageRepository imageRepository,
) async {
  final encoded = <Map<String, dynamic>>[];
  for (final feature in features) {
    encoded.add(
      await encodeFeature(
        feature,
        imageRepository,
        mode: FeaturePersistenceMode.clipboard,
      ),
    );
  }
  return jsonEncode({'features': encoded});
}

Future<List<Feature>?> decodeFeaturesFromClipboard(
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
      final feature = await decodeFeatureAsync(
        raw as Map<String, dynamic>,
        imageRepository,
        mode: FeaturePersistenceMode.clipboard,
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

Future<Map<String, dynamic>> encodeFeature(
  Feature feature,
  ImageRepository imageRepository, {
  required FeaturePersistenceMode mode,
}) async {
  final json = <String, dynamic>{
    'origin': encodeOffset(feature.origin),
    'size': encodeSize(feature.size),
    'kind': await encodeKind(feature.kind, imageRepository, mode: mode),
  };

  if (mode == FeaturePersistenceMode.document) {
    json['id'] = feature.id.value;
  }

  return json;
}

Feature? decodeFeature(
  Map<String, dynamic> json, {
  required FeaturePersistenceMode mode,
}) {
  final kindJson = json['kind'] as Map<String, dynamic>?;
  if (kindJson == null) {
    return null;
  }

  final kind = decodeKind(kindJson, mode: mode);
  if (kind == null) {
    return null;
  }

  final id = mode == FeaturePersistenceMode.document
      ? FeatureId.newId(json['id'] as int)
      : noId;

  return Feature(
    id: id,
    origin: decodeOffset(json['origin'] as Map<String, dynamic>),
    size: decodeSize(json['size'] as Map<String, dynamic>),
    kind: kind,
  );
}

Future<Feature?> decodeFeatureAsync(
  Map<String, dynamic> json,
  ImageRepository imageRepository, {
  required FeaturePersistenceMode mode,
}) async {
  final kindJson = json['kind'] as Map<String, dynamic>?;
  if (kindJson == null) {
    return null;
  }

  final kind = await decodeKindAsync(kindJson, imageRepository, mode: mode);
  if (kind == null) {
    return null;
  }

  final id = mode == FeaturePersistenceMode.document
      ? FeatureId.newId(json['id'] as int)
      : noId;

  return Feature(
    id: id,
    origin: decodeOffset(json['origin'] as Map<String, dynamic>),
    size: decodeSize(json['size'] as Map<String, dynamic>),
    kind: kind,
  );
}

Future<Map<String, dynamic>> encodeKind(
  FeatureKind kind,
  ImageRepository imageRepository, {
  required FeaturePersistenceMode mode,
}) async {
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
        for (final point in kind.localPoints) encodeOffset(point),
      ],
      'strokeColor': kind.strokeColor.toARGB32(),
      'fillColor': kind.fillColor.toARGB32(),
      'strokeWidth': kind.strokeWidth,
    },
    FeatureKindImage() => {
      'type': 'image',
      'strokeColor': kind.strokeColor.toARGB32(),
      'strokeWidth': kind.strokeWidth,
      if (mode == FeaturePersistenceMode.document)
        'imageId': kind.imageId
      else
        'pngBase64': base64Encode(
          await imageRepository.readPngBytes(kind.imageId) ?? Uint8List(0),
        ),
    },
  };
}

FeatureKind? decodeKind(
  Map<String, dynamic> json, {
  required FeaturePersistenceMode mode,
}) {
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
          decodeOffset(point as Map<String, dynamic>),
      ],
      strokeColor: Color(json['strokeColor'] as int),
      fillColor: Color(json['fillColor'] as int),
      strokeWidth: (json['strokeWidth'] as num).toDouble(),
    ),
    'image' when mode == FeaturePersistenceMode.document =>
      _decodeDocumentImageKind(json),
    _ => null,
  };
}

Future<FeatureKind?> decodeKindAsync(
  Map<String, dynamic> json,
  ImageRepository imageRepository, {
  required FeaturePersistenceMode mode,
}) async {
  if (mode == FeaturePersistenceMode.document) {
    return decodeKind(json, mode: mode);
  }

  return switch (json['type'] as String?) {
    'rectangle' ||
    'circle' ||
    'text' ||
    'polyline' => decodeKind(json, mode: mode),
    'image' => _decodeClipboardImageKind(json, imageRepository),
    _ => null,
  };
}

FeatureKindImage? _decodeDocumentImageKind(Map<String, dynamic> json) {
  final imageId = json['imageId'] as String?;
  if (imageId == null || imageId.isEmpty) {
    return null;
  }

  return FeatureKindImage(
    imageId,
    strokeColor: Color(json['strokeColor'] as int),
    strokeWidth: (json['strokeWidth'] as num).toDouble(),
  );
}

Future<FeatureKindImage?> _decodeClipboardImageKind(
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

Map<String, dynamic> encodeOffset(Offset offset) => {
  'x': offset.dx,
  'y': offset.dy,
};

Offset decodeOffset(Map<String, dynamic> json) =>
    Offset((json['x'] as num).toDouble(), (json['y'] as num).toDouble());

Map<String, dynamic> encodeSize(Size size) => {
  'width': size.width,
  'height': size.height,
};

Size decodeSize(Map<String, dynamic> json) => Size(
  (json['width'] as num).toDouble(),
  (json['height'] as num).toDouble(),
);
