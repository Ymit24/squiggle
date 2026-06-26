import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

Future<Uint8List> _createTestPngBytes({int width = 100, int height = 50}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFF0000),
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  return byteData!.buffer.asUint8List();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('clampImageWorldSize', () {
    test('returns intrinsic size when within max dimension', () {
      expect(
        clampImageWorldSize(const Size(400, 200)),
        const Size(400, 200),
      );
    });

    test('scales down large images preserving aspect ratio', () {
      expect(
        clampImageWorldSize(const Size(2048, 1024)),
        const Size(1024, 512),
      );
    });
  });

  group('ImageRepository', () {
    late Directory tempDir;
    late ImageRepository repository;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('squiggle_image_test');
      repository = ImageRepository(imagesDirectory: tempDir);
      await repository.initialize();
    });

    tearDown(() async {
      repository.dispose();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('importPngBytes writes file, caches image, and returns intrinsic size',
        () async {
      final bytes = await _createTestPngBytes();
      final imported = await repository.importPngBytes(bytes);

      expect(imported, isNotNull);
      expect(imported!.intrinsicSize, const Size(100, 50));
      expect(await repository.fileFor(imported.imageId).exists(), isTrue);
      expect(repository.getCached(imported.imageId), isNotNull);
    });

    test('requestImage loads from disk when not cached', () async {
      final bytes = await _createTestPngBytes(width: 64, height: 32);
      final imported = await repository.importPngBytes(bytes);
      expect(imported, isNotNull);

      final freshRepository = ImageRepository(imagesDirectory: tempDir);
      await freshRepository.initialize();

      expect(freshRepository.getCached(imported!.imageId), isNull);

      freshRepository.requestImage(imported.imageId);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(freshRepository.getCached(imported.imageId), isNotNull);
      freshRepository.dispose();
    });
  });
}
