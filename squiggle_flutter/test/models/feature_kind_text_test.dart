import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/selection_resize_handle.dart';

void main() {
  group('FeatureKindText serde', () {
    final content = {
      'type': 'text',
      'contents': 'Hello',
      'sizing': 'fixedWidth',
      'fontSize': 24.5,
      'horizontalAlignment': 'center',
      'verticalAlignment': 'bottom',
      'strokeColor': 0xFF112233,
    };

    test('fromDataModel preserves text and style fields', () {
      final kind = FeatureKindText.fromDataModel(content);
      expect(kind.label, 'Hello');
      expect(kind.sizing, TextSizing.fixedWidth);
      expect(kind.fontSize, 24.5);
      expect(kind.horizontalAlignment, TextHorizontalAlignment.center);
      expect(kind.verticalAlignment, TextVerticalAlignment.bottom);
      expect(kind.strokeColor.toARGB32(), 0xFF112233);
    });

    test('toDataModel emits all text and style fields', () {
      final kind = FeatureKindText(
        'Hello',
        sizing: TextSizing.fixedWidth,
        fontSize: 24.5,
        horizontalAlignment: TextHorizontalAlignment.center,
        verticalAlignment: TextVerticalAlignment.bottom,
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
      expect(result.verticalAlignment, decoded.verticalAlignment);
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
      expect(
        () => FeatureKindText.fromDataModel({
          ...content,
          'verticalAlignment': 'invalid',
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

    test('corner handle scales the font about the opposite corner', () {
      final feature = textFeature();
      final initial = feature.copyWith();
      final start = feature.localBounds();

      feature.resizeFromHandle(
        Rect.fromLTRB(
          start.left,
          start.top,
          start.left + start.width * 2,
          start.top + start.height * 2,
        ),
        SelectionResizeHandle.bottomRight,
        initial,
      );

      expect((feature.kind as FeatureKindText).fontSize, closeTo(48, 1e-9));
      expect(feature.origin, start.topLeft);
      expect(feature.width, closeTo(start.width * 2, 3));
    });

    test('font size changes smoothly as the corner moves in any direction', () {
      final feature = textFeature();
      final initial = feature.copyWith();
      final start = feature.localBounds();
      final kind = feature.kind as FeatureKindText;
      double? previous;

      // Sweep the pointer from a horizontal-heavy to a vertical-heavy drag.
      for (var step = 0; step <= 100; step++) {
        final t = step / 100;
        final corner = Offset(
          start.right + 40 * (1 - t),
          start.bottom + 40 * t,
        );
        feature.resizeFromHandle(
          Rect.fromPoints(start.topLeft, corner),
          SelectionResizeHandle.bottomRight,
          initial,
        );

        if (previous != null) {
          expect((kind.fontSize - previous).abs(), lessThan(0.5));
        }
        previous = kind.fontSize;
      }
    });

    test('top-left corner keeps the bottom-right corner fixed', () {
      final feature = textFeature();
      final initial = feature.copyWith();
      final start = feature.localBounds();

      feature.resizeFromHandle(
        Rect.fromLTRB(
          start.right - start.width / 2,
          start.bottom - start.height / 2,
          start.right,
          start.bottom,
        ),
        SelectionResizeHandle.topLeft,
        initial,
      );

      expect((feature.kind as FeatureKindText).fontSize, closeTo(12, 1e-9));
      expect(feature.localBounds().bottomRight.dx, closeTo(start.right, 1e-9));
      expect(feature.localBounds().bottomRight.dy, closeTo(start.bottom, 1e-9));
    });

    test('repeated corner moves do not compound', () {
      final feature = textFeature();
      final initial = feature.copyWith();
      final start = feature.localBounds();
      Rect scaled(double factor) => Rect.fromLTWH(
        start.left,
        start.top,
        start.width * factor,
        start.height * factor,
      );

      for (final factor in [1.5, 3.0, 2.0]) {
        feature.resizeFromHandle(
          scaled(factor),
          SelectionResizeHandle.bottomRight,
          initial,
        );
      }

      expect((feature.kind as FeatureKindText).fontSize, closeTo(48, 1e-9));
    });

    test('side handle sets the wrap width and keeps the font size', () {
      final feature = textFeature();
      final initial = feature.copyWith();
      final start = feature.localBounds();

      feature.resizeFromHandle(
        Rect.fromLTRB(start.left, start.top, start.left + 120, start.bottom),
        SelectionResizeHandle.right,
        initial,
      );

      final kind = feature.kind as FeatureKindText;
      expect(kind.sizing, TextSizing.fixedWidth);
      expect(kind.fontSize, 24);
      expect(feature.width, 120);
      expect(feature.origin, start.topLeft);
      expect(feature.height, greaterThan(start.height));
      expect(
        feature.height,
        kind.measureContents(fontSize: 24, width: 120).height,
      );
    });

    test('left handle keeps the right edge fixed', () {
      final feature = textFeature(sizing: TextSizing.fixedWidth);
      final initial = feature.copyWith();
      final start = feature.localBounds();

      feature.resizeFromHandle(
        Rect.fromLTRB(start.right - 100, start.top, start.right, start.bottom),
        SelectionResizeHandle.left,
        initial,
      );

      expect(feature.localBounds().right, start.right);
      expect(feature.width, 100);
    });

    test('top and bottom handles are not offered for text', () {
      final feature = textFeature();

      expect(feature.supportsResizeHandle(SelectionResizeHandle.top), isFalse);
      expect(
        feature.supportsResizeHandle(SelectionResizeHandle.bottom),
        isFalse,
      );
      expect(feature.supportsResizeHandle(SelectionResizeHandle.left), isTrue);
      expect(
        feature.supportsResizeHandle(SelectionResizeHandle.topLeft),
        isTrue,
      );
    });

    test('group-style resize scales the font with the box', () {
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
