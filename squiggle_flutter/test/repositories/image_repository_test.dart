import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

import '../support/test_database.dart';

Future<Uint8List> _createTestPngBytes({
  int width = 100,
  int height = 50,
}) async {
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
      expect(clampImageWorldSize(const Size(400, 200)), const Size(400, 200));
    });

    test('scales down large images preserving aspect ratio', () {
      expect(
        clampImageWorldSize(const Size(2048, 1024)),
        const Size(1024, 512),
      );
    });
  });

  group('ImageRepository', () {
    late AppDatabase database;
    late ImageRepository repository;

    setUp(() {
      database = createTestDatabase();
      repository = ImageRepository(images: database.imagesDao);
    });

    tearDown(() async {
      repository.dispose();
      await database.close();
    });

    test('importPngBytes stores the bytes, caches the image, and returns the hash id', () async {
      final bytes = await _createTestPngBytes();
      final imported = await repository.importPngBytes(bytes);

      expect(imported, isNotNull);
      expect(imported!.imageId, sha256.convert(bytes).toString());
      expect(imported.intrinsicSize, const Size(100, 50));
      expect(await repository.readPngBytes(imported.imageId), bytes);
      expect(repository.getCached(imported.imageId), isNotNull);
    });

    test('importing the same bytes twice returns one id and one row', () async {
      final bytes = await _createTestPngBytes();

      final first = await repository.importPngBytes(bytes);
      final cached = repository.getCached(first!.imageId);
      final second = await repository.importPngBytes(bytes);

      expect(second!.imageId, first.imageId);
      expect(repository.getCached(first.imageId), same(cached));
      expect(await database.select(database.images).get(), hasLength(1));
    });

    test('requestImage loads from the database when not cached', () async {
      final bytes = await _createTestPngBytes(width: 64, height: 32);
      final imported = await repository.importPngBytes(bytes);
      expect(imported, isNotNull);

      final freshRepository = ImageRepository(images: database.imagesDao);

      expect(freshRepository.getCached(imported!.imageId), isNull);

      freshRepository.requestImage(imported.imageId);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(freshRepository.getCached(imported.imageId), isNotNull);
      freshRepository.dispose();
    });

    test('an image that is not stored is never cached', () async {
      repository.requestImage('missing');
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(repository.getCached('missing'), isNull);
      expect(await repository.readPngBytes('missing'), isNull);
    });
  });
}
