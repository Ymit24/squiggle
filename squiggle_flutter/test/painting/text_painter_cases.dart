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

  group('fontSizeFillingBounds', () {
    test('finds a font size that fits the requested bounds', () {
      final fontSize = fontSizeFillingBounds(
        'one two three four five',
        width: 120,
        height: 60,
      );

      expect(fontSize, isNotNull);
      expect(
        measureText(
          'one two three four five',
          width: 120,
          fontSize: fontSize!,
        ).height,
        lessThanOrEqualTo(60),
      );
    });

    test('returns null when the minimum font size cannot fit', () {
      expect(fontSizeFillingBounds('text', width: 100, height: 0), isNull);
    });

    test('does not exceed the maximum font size', () {
      expect(
        fontSizeFillingBounds('', width: 100, height: 2000),
        kMaxTextFontSize,
      );
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
