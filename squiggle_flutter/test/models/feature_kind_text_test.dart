import 'dart:ui';

import 'package:flutter/painting.dart' show Alignment;

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/resize_drag.dart';

void main() {
  group('FeatureKindText serde', () {
    final content = {
      'type': 'text',
      'contents': 'Hello',
      'sizing': 'fixedWidth',
      'fontSize': 24.5,
      'horizontalAlignment': 'center',
      'strokeColor': 0xFF112233,
    };

    test('fromDataModel preserves text and style fields', () {
      final kind = FeatureKindText.fromDataModel(content);
      expect(kind.label, 'Hello');
      expect(kind.sizing, TextSizing.fixedWidth);
      expect(kind.fontSize, 24.5);
      expect(kind.horizontalAlignment, TextHorizontalAlignment.center);
      expect(kind.strokeColor.toARGB32(), 0xFF112233);
    });

    test('toDataModel emits all text and style fields', () {
      final kind = FeatureKindText(
        'Hello',
        sizing: TextSizing.fixedWidth,
        fontSize: 24.5,
        horizontalAlignment: TextHorizontalAlignment.center,
        strokeColor: Color(0xFF112233),
      );
      expect(kind.toDataModel(), content);
    });

    test('round trip preserves text and style fields', () {
      final decoded = FeatureKindText.fromDataModel(content);
      final result = FeatureKindText.fromDataModel(decoded.toDataModel());
      expect(result.label, decoded.label);
      expect(result.sizing, decoded.sizing);
      expect(result.fontSize, decoded.fontSize);
      expect(result.horizontalAlignment, decoded.horizontalAlignment);
      expect(result.strokeColor, decoded.strokeColor);
    });

    test('invalid alignment names throw ArgumentError', () {
      expect(
        () => FeatureKindText.fromDataModel({
          ...content,
          'horizontalAlignment': 'invalid',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('setLabel', () {
    test('fixed width keeps width and fits height to contents', () {
      final kind = FeatureKindText(
        'short',
        sizing: TextSizing.fixedWidth,
        fontSize: 24,
      );
      final feature = Feature(
        origin: const Offset(10, 20),
        size: const Size(100, 200),
        kind: kind,
      );

      kind.setLabel(feature, 'a long line that wraps across several lines');

      expect(feature.origin, const Offset(10, 20));
      expect(feature.width, 100);
      expect(
        feature.height,
        kind.measureContents(width: 100, fontSize: 24).height,
      );
      expect(kind.fontSize, 24);
    });

    test('auto width grows to the longest line without wrapping', () {
      final kind = FeatureKindText('a', fontSize: 24);
      final feature = Feature(
        origin: const Offset(10, 20),
        size: kind.measureContents(fontSize: 24),
        kind: kind,
      );
      final oneLineHeight = feature.height;

      kind.setLabel(feature, 'a much longer single line of text');

      expect(feature.width, greaterThan(200));
      expect(feature.height, oneLineHeight);
      expect(feature.origin, const Offset(10, 20));
    });

    for (final (alignment, anchor) in [
      (TextHorizontalAlignment.left, 0.0),
      (TextHorizontalAlignment.center, 0.5),
      (TextHorizontalAlignment.right, 1.0),
    ]) {
      test('auto width keeps the ${alignment.name} alignment point fixed', () {
        final kind = FeatureKindText('a', horizontalAlignment: alignment);
        final feature = Feature(
          origin: const Offset(100, 0),
          size: kind.measureContents(fontSize: kind.fontSize),
          kind: kind,
        );
        final anchorX = feature.origin.dx + feature.width * anchor;

        kind.setLabel(feature, 'much longer');

        expect(
          feature.origin.dx + feature.width * anchor,
          closeTo(anchorX, 1e-9),
        );
      });
    }

    test('empty content has the height of one line', () {
      final kind = FeatureKindText(
        'text',
        sizing: TextSizing.fixedWidth,
        fontSize: 24,
      );
      final feature = Feature(
        origin: Offset.zero,
        size: const Size(100, 200),
        kind: kind,
      );

      kind.setLabel(feature, '');

      expect(feature.height, greaterThan(0));
      expect(
        feature.height,
        kind.measureContents(width: 100, fontSize: 24).height,
      );
    });
  });

  group('resizing', () {
    const bottomRightCorner = ResizeDrag(
      fixedPoint: Alignment.topLeft,
      isCorner: true,
    );
    const topLeftCorner = ResizeDrag(
      fixedPoint: Alignment.bottomRight,
      isCorner: true,
    );

    Feature textFeature({TextSizing sizing = TextSizing.auto}) {
      final kind = FeatureKindText(
        'one two three four five six',
        sizing: sizing,
        fontSize: 24,
      );
      return Feature(
        origin: const Offset(100, 100),
        size: kind.measureContents(
          fontSize: 24,
          width: sizing == TextSizing.fixedWidth ? 200 : null,
        ),
        kind: kind,
      );
    }

    Rect scaledBounds(Rect start, double factor, {Alignment pin = .topLeft}) {
      final size = start.size * factor;
      final anchor = pin.withinRect(start);
      return Rect.fromLTWH(
        anchor.dx - size.width * (pin.x + 1) / 2,
        anchor.dy - size.height * (pin.y + 1) / 2,
        size.width,
        size.height,
      );
    }

    test('corner drag scales the font about the fixed corner', () {
      final feature = textFeature();
      final start = feature.localBounds();

      feature.resize(scaledBounds(start, 2), drag: bottomRightCorner);

      expect((feature.kind as FeatureKindText).fontSize, closeTo(48, 1e-9));
      expect(feature.origin, start.topLeft);
      expect(feature.width, closeTo(start.width * 2, 3));
    });

    test('top-left corner drag keeps the bottom-right corner fixed', () {
      final feature = textFeature();
      final start = feature.localBounds();

      feature.resize(
        scaledBounds(start, 0.5, pin: Alignment.bottomRight),
        drag: topLeftCorner,
      );

      expect((feature.kind as FeatureKindText).fontSize, closeTo(12, 1e-9));
      final end = feature.localBounds();
      expect(end.right, closeTo(start.right, 1e-9));
      expect(end.bottom, closeTo(start.bottom, 1e-9));
    });

    test('dragging a corner past the fixed corner grows the other way', () {
      final feature = textFeature();
      final start = feature.localBounds();

      feature.resize(
        Rect.fromLTRB(
          start.left - start.width,
          start.top - start.height,
          start.left,
          start.top,
        ),
        drag: bottomRightCorner,
      );

      final end = feature.localBounds();
      expect(end.right, closeTo(start.left, 1e-9));
      expect(end.bottom, closeTo(start.top, 1e-9));
    });

    test('a symmetric corner drag keeps the centre fixed', () {
      final feature = textFeature();
      final start = feature.localBounds();

      feature.resize(
        scaledBounds(start, 2, pin: Alignment.center),
        drag: const ResizeDrag(fixedPoint: Alignment.center, isCorner: true),
      );

      expect(feature.localBounds().center.dx, closeTo(start.center.dx, 1e-9));
      expect(feature.localBounds().center.dy, closeTo(start.center.dy, 1e-9));
    });

    test('font size changes smoothly as the corner moves in any direction', () {
      final start = textFeature().localBounds();
      final snapshot = textFeature().toDataModel();
      final feature = textFeature();
      double? previous;

      // Sweep the pointer from a horizontal-heavy to a vertical-heavy drag.
      for (var step = 0; step <= 100; step++) {
        final t = step / 100;
        feature.restoreFromDataModel(snapshot);
        feature.resize(
          Rect.fromPoints(
            start.topLeft,
            Offset(start.right + 40 * (1 - t), start.bottom + 40 * t),
          ),
          drag: bottomRightCorner,
        );

        final fontSize = (feature.kind as FeatureKindText).fontSize;
        if (previous != null) {
          expect((fontSize - previous).abs(), lessThan(0.5));
        }
        previous = fontSize;
      }
    });

    test('side drag sets the wrap width and keeps the font size', () {
      final feature = textFeature();
      final start = feature.localBounds();

      feature.resize(
        Rect.fromLTRB(start.left, start.top, start.left + 120, start.bottom),
        drag: const ResizeDrag(
          fixedPoint: Alignment.centerLeft,
          isCorner: false,
        ),
      );

      final kind = feature.kind as FeatureKindText;
      expect(kind.sizing, TextSizing.fixedWidth);
      expect(kind.fontSize, 24);
      expect(feature.width, 120);
      expect(feature.origin, start.topLeft);
      expect(
        feature.height,
        kind.measureContents(fontSize: 24, width: 120).height,
      );
      expect(feature.height, greaterThan(start.height));
    });

    test('left side drag keeps the right edge fixed', () {
      final feature = textFeature(sizing: TextSizing.fixedWidth);
      final start = feature.localBounds();

      feature.resize(
        Rect.fromLTRB(start.right - 100, start.top, start.right, start.bottom),
        drag: const ResizeDrag(
          fixedPoint: Alignment.centerRight,
          isCorner: false,
        ),
      );

      expect(feature.localBounds().right, start.right);
      expect(feature.width, 100);
    });

    test('side drag never goes narrower than one em', () {
      final feature = textFeature();
      final start = feature.localBounds();

      feature.resize(
        Rect.fromLTRB(start.left, start.top, start.left + 1, start.bottom),
        drag: const ResizeDrag(
          fixedPoint: Alignment.centerLeft,
          isCorner: false,
        ),
      );

      expect(feature.width, 24);
    });

    test('text does not offer top and bottom handles', () {
      expect(textFeature().supportsVerticalResize, isFalse);
    });

    test('a plain resize scales the font and pins the top-left', () {
      final feature = textFeature();
      final start = feature.localBounds();

      feature.resize(Rect.fromLTWH(0, 0, start.width / 2, start.height / 2));

      expect((feature.kind as FeatureKindText).fontSize, closeTo(12, 1e-9));
      expect(feature.origin, Offset.zero);
    });
  });

  group('refit', () {
    test('switching to auto drops the wrap width', () {
      final kind = FeatureKindText(
        'hello',
        sizing: TextSizing.fixedWidth,
        fontSize: 24,
      );
      final feature = Feature(
        origin: Offset.zero,
        size: const Size(400, 40),
        kind: kind,
      );

      kind.sizing = TextSizing.auto;
      kind.refit(feature);

      expect(feature.width, 5 * 24);
    });
  });
}
