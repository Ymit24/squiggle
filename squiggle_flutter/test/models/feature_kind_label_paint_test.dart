import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

void main() {
  for (final testCase in <({String name, FeatureKind Function(String) create})>[
    (
      name: 'rectangle',
      create: (label) => FeatureKindRectangle(
        label: label,
        fillColor: const Color(0x00000000),
        strokeColor: const Color(0x00000000),
      ),
    ),
    (
      name: 'circle',
      create: (label) => FeatureKindCircle(
        label: label,
        fillColor: const Color(0x00000000),
        strokeColor: const Color(0x00000000),
      ),
    ),
  ]) {
    test('${testCase.name} paints a non-empty label', () async {
      final pixels = await _paintFeature(testCase.create('label'));

      expect(_paintedPixelCount(pixels), greaterThan(0));
    });

    test('${testCase.name} does not paint an empty label', () async {
      final pixels = await _paintFeature(testCase.create(''));

      expect(_paintedPixelCount(pixels), 0);
    });
  }
}

Future<ByteData> _paintFeature(FeatureKind kind) async {
  final feature = Feature(
    origin: const Offset(10, 10),
    size: const Size(100, 60),
    kind: kind,
  );
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  final imageRepository = ImageRepository();
  feature.paint(canvas, imageRepository);
  final picture = recorder.endRecording();
  final image = await picture.toImage(120, 80);
  final pixels = (await image.toByteData(format: ImageByteFormat.rawRgba))!;
  image.dispose();
  picture.dispose();
  imageRepository.dispose();
  return pixels;
}

int _paintedPixelCount(ByteData pixels) {
  var count = 0;
  for (var offset = 3; offset < pixels.lengthInBytes; offset += 4) {
    if (pixels.getUint8(offset) != 0) count++;
  }
  return count;
}
