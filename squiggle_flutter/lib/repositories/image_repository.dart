import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/repositories/image_store.dart';

/// Result of importing a clipboard image into app storage.
class ImportedImage {
  const ImportedImage({required this.imageId, required this.intrinsicSize});

  final String imageId;
  final Size intrinsicSize;
}

/// Decodes stored images lazily and caches them for canvas rendering.
class ImageRepository {
  ImageRepository({ImageStore? store}) : _store = store ?? ImageStore();

  final ImageStore _store;
  final Map<String, ui.Image> _cache = {};
  final Map<String, Future<ui.Image?>> _loading = {};
  final StreamController<void> _repaintController =
      StreamController<void>.broadcast();

  Stream<void> get repaintStream => _repaintController.stream;

  ui.Image? getCached(String imageId) => _cache[imageId];

  void requestImage(String imageId) {
    if (_cache.containsKey(imageId) || _loading.containsKey(imageId)) {
      return;
    }

    _loading[imageId] = _loadImage(imageId).then((image) {
      _loading.remove(imageId);
      if (image != null) {
        _cache[imageId] = image;
        _repaintController.add(null);
      }
      return image;
    });
  }

  Future<Uint8List?> readPngBytes(String imageId) => _store.get(imageId);

  /// Stores [bytes] and caches the decoded image under the content-hash id.
  ///
  /// Importing bytes that are already stored returns the same id.
  Future<ImportedImage?> importPngBytes(Uint8List bytes) async {
    final decoded = await _decodeImage(bytes);
    if (decoded == null) {
      return null;
    }

    final imageId = await _store.put(bytes);
    final cached = _cache[imageId];
    if (cached == null) {
      _cache[imageId] = decoded.image;
    } else {
      decoded.image.dispose();
    }

    return ImportedImage(imageId: imageId, intrinsicSize: decoded.size);
  }

  void dispose() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _repaintController.close();
  }

  Future<ui.Image?> _loadImage(String imageId) async {
    final bytes = await _store.get(imageId);
    if (bytes == null) {
      return null;
    }

    final decoded = await _decodeImage(bytes);
    return decoded?.image;
  }

  Future<({ui.Image image, Size size})?> _decodeImage(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    return (
      image: image,
      size: Size(image.width.toDouble(), image.height.toDouble()),
    );
  }
}

/// Scales very large pasted images down to a reasonable canvas size.
Size clampImageWorldSize(Size intrinsicSize, {double maxDimension = 1024}) {
  final width = intrinsicSize.width;
  final height = intrinsicSize.height;
  if (width <= 0 || height <= 0) {
    return const Size(256, 256);
  }
  if (width <= maxDimension && height <= maxDimension) {
    return intrinsicSize;
  }

  final scale = maxDimension / math.max(width, height);
  return Size(width * scale, height * scale);
}
