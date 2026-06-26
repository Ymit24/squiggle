import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:super_clipboard/super_clipboard.dart';

/// Result of importing a clipboard image into app storage.
class ImportedImage {
  const ImportedImage({
    required this.imageId,
    required this.intrinsicSize,
  });

  final String imageId;
  final Size intrinsicSize;
}

/// Stores pasted images on disk and lazily decodes them for canvas rendering.
class ImageRepository {
  ImageRepository({Directory? imagesDirectory})
    : _imagesDirectory = imagesDirectory;

  Directory? _imagesDirectory;
  final Map<String, ui.Image> _cache = {};
  final Map<String, Future<ui.Image?>> _loading = {};
  final StreamController<void> _repaintController =
      StreamController<void>.broadcast();

  Stream<void> get repaintStream => _repaintController.stream;

  Directory? get imagesDirectory => _imagesDirectory;

  Future<void> initialize() async {
    _imagesDirectory ??= await _defaultImagesDirectory();
    await _imagesDirectory!.create(recursive: true);
  }

  Future<Directory> _defaultImagesDirectory() async {
    final supportDir = await getApplicationSupportDirectory();
    return Directory('${supportDir.path}/Squiggle/images');
  }

  File fileFor(String imageId) {
    final directory = _imagesDirectory;
    if (directory == null) {
      throw StateError('ImageRepository.initialize() must be called first.');
    }
    return File('${directory.path}/$imageId');
  }

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

  Future<ImportedImage?> importFromClipboard() async {
    final bytes = await _readClipboardPngBytes();
    if (bytes == null) {
      return null;
    }
    return importPngBytes(bytes);
  }

  Future<ImportedImage?> importPngBytes(Uint8List bytes) async {
    await initialize();

    final decoded = await _decodeImage(bytes);
    if (decoded == null) {
      return null;
    }

    final imageId = _generateImageId();
    await fileFor(imageId).writeAsBytes(bytes, flush: true);
    _cache[imageId] = decoded.image;

    return ImportedImage(
      imageId: imageId,
      intrinsicSize: decoded.size,
    );
  }

  Future<Uint8List?> _readClipboardPngBytes() async {
    final clipboard = SystemClipboard.instance;
    if (clipboard == null) {
      return null;
    }

    final reader = await clipboard.read();
    for (final item in reader.items) {
      if (!item.canProvide(Formats.png)) {
        continue;
      }

      final completer = Completer<Uint8List?>();
      final progress = item.getFile(
        Formats.png,
        (file) async {
          try {
            completer.complete(await file.readAll());
          } catch (_) {
            completer.complete(null);
          }
        },
        onError: (_) {
          completer.complete(null);
        },
      );
      if (progress == null) {
        continue;
      }
      return completer.future;
    }

    return null;
  }

  Future<ui.Image?> _loadImage(String imageId) async {
    await initialize();

    final file = fileFor(imageId);
    if (!await file.exists()) {
      return null;
    }

    final bytes = await file.readAsBytes();
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

  String _generateImageId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = math.Random().nextInt(0xFFFFFF);
    return 'img_${timestamp}_${random.toRadixString(16).padLeft(6, '0')}.png';
  }

  void dispose() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
    _repaintController.close();
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
