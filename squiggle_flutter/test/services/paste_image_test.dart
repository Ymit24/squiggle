import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/paste_image.dart';

void main() {
  group('createImageFeatureAtCenter', () {
    test('creates centered image feature with clamped size', () {
      const imported = ImportedImage(
        imageId: 'img_test.png',
        intrinsicSize: Size(2048, 1024),
      );

      final feature = createImageFeatureAtCenter(
        imported: imported,
        center: const Offset(500, 400),
      );

      expect(feature.kind, isA<FeatureKindImage>());
      expect((feature.kind as FeatureKindImage).imageId, 'img_test.png');
      expect(feature.size, const Size(1024, 512));
      expect(feature.origin, const Offset(500 - 512, 400 - 256));
      expect(feature.bounds().center, const Offset(500, 400));
    });
  });
}
