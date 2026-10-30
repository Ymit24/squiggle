import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/painting/text_painter.dart';

void main() {
  group('measureText', () {
    test('returns the requested width and wraps at narrower widths', () {
      final wide = measureText(
        'one two three four five',
        width: 300,
        fontSize: 20,
      );
      final narrow = measureText(
        'one two three four five',
        width: 50,
        fontSize: 20,
      );

      expect(wide.width, 300);
      expect(narrow.width, 50);
      expect(narrow.height, greaterThan(wide.height));
    });
  });

  group('measureTextIntrinsic', () {
    test('does not wrap and fits the longest line', () {
      final single = measureTextIntrinsic('one two three four', fontSize: 24);
      final longer = measureTextIntrinsic(
        'one two three four\nshort',
        fontSize: 24,
      );

      expect(longer.width, single.width);
      expect(longer.height, greaterThan(single.height));
      expect(
        measureText(
          'one two three four',
          width: single.width,
          fontSize: 24,
        ).height,
        single.height,
      );
    });

    test('width is a whole number of units', () {
      final size = measureTextIntrinsic('squiggle', fontSize: 23.7);

      expect(size.width, size.width.ceilToDouble());
    });
  });

  group('paintText', () {
    test('does not paint when the fill color is disabled', () async {
      final pixels = await _render((canvas) {
        paintText(
          canvas,
          'label',
          const Rect.fromLTWH(20, 20, 60, 40),
          fillColor: null,
        );
      });

      expect(_paintedPixelCount(pixels), 0);
    });

    test('paints a visible label', () async {
      final pixels = await _render((canvas) {
        paintText(
          canvas,
          'label',
          const Rect.fromLTWH(20, 20, 60, 40),
          fillColor: const Color(0xFFFFFFFF),
        );
      });

      expect(_paintedPixelCount(pixels), greaterThan(0));
    });

    test('clips overflowing text to its bounds by default', () async {
      const bounds = Rect.fromLTWH(30, 45, 40, 8);
      final clipped = await _render((canvas) {
        paintText(
          canvas,
          'MMMM',
          bounds,
          fontSize: 40,
          fillColor: const Color(0xFFFFFFFF),
        );
      });
      final unclipped = await _render((canvas) {
        paintText(
          canvas,
          'MMMM',
          bounds,
          fontSize: 40,
          fillColor: const Color(0xFFFFFFFF),
          clipToBounds: false,
        );
      });

      expect(_paintedPixelCount(clipped), greaterThan(0));
      expect(_paintedPixelsOutside(clipped, bounds), 0);
      expect(_paintedPixelsOutside(unclipped, bounds), greaterThan(0));
    });
  });
}

const _imageWidth = 100;
const _imageHeight = 100;

Future<ByteData> _render(void Function(Canvas canvas) paint) async {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  paint(canvas);
  final picture = recorder.endRecording();
  final image = await picture.toImage(_imageWidth, _imageHeight);
  final pixels = (await image.toByteData(format: ImageByteFormat.rawRgba))!;
  image.dispose();
  picture.dispose();
  return pixels;
}

int _paintedPixelCount(ByteData pixels) {
  var count = 0;
  for (var offset = 3; offset < pixels.lengthInBytes; offset += 4) {
    if (pixels.getUint8(offset) != 0) count++;
  }
  return count;
}

int _paintedPixelsOutside(ByteData pixels, Rect bounds) {
  var count = 0;
  for (var y = 0; y < _imageHeight; y++) {
    for (var x = 0; x < _imageWidth; x++) {
      final alpha = pixels.getUint8((y * _imageWidth + x) * 4 + 3);
      if (alpha != 0 && !bounds.contains(Offset(x.toDouble(), y.toDouble()))) {
        count++;
      }
    }
  }
  return count;
}
