import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import 'feature_id.dart';

/// A drawable shape or label in world space.
class Feature {
  Feature({
    required this.id,
    required this.origin,
    required this.size,
    required this.kind,
  });

  FeatureId id;
  Offset origin;
  Size size;
  FeatureKind kind;

  factory Feature.newRectangle(Offset origin, Size size) => Feature(
    id: noId,
    origin: origin,
    size: size,
    kind: const FeatureKindRectangle(),
  );

  factory Feature.newCircle(Offset origin, Size size) => Feature(
    id: noId,
    origin: origin,
    size: size,
    kind: const FeatureKindCircle(),
  );

  factory Feature.newText(Offset origin, Size size, String contents) => Feature(
    id: noId,
    origin: origin,
    size: size,
    kind: FeatureKindText(contents),
  );

  double get width => size.width;

  double get height => size.height;

  Rect bounds() => Rect.fromLTWH(origin.dx, origin.dy, size.width, size.height);

  void setBounds(Rect bounds) {
    origin = bounds.topLeft;
    size = bounds.size;
  }

  Offset center() => bounds().center;

  void moveTo(Offset newOrigin) {
    origin = newOrigin;
  }

  Feature copyWith({
    FeatureId? id,
    Offset? origin,
    Size? size,
    FeatureKind? kind,
  }) => Feature(
    id: id ?? this.id,
    origin: origin ?? this.origin,
    size: size ?? this.size,
    kind: kind ?? this.kind,
  );

  void paint(Canvas canvas, Rect worldBounds) {
    switch (kind) {
      case FeatureKindRectangle():
        canvas.drawRect(worldBounds, Paint()..color = const Color(0xFFCDA6F7));
      case FeatureKindCircle():
        canvas.drawOval(worldBounds, Paint()..color = const Color(0xFFF38BA8));
      case FeatureKindText(:final contents):
        _paintText(canvas, contents, worldBounds);
    }
  }

  void _paintText(Canvas canvas, String contents, Rect worldBounds) {
    if (contents.isEmpty) return;

    final fontSize = worldBounds.height;
    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textAlign: TextAlign.left,
        fontSize: fontSize,
        textDirection: TextDirection.ltr,
      ),
    )..pushStyle(ui.TextStyle(color: const Color(0xFFCDD6F4)));
    builder.addText(contents);

    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: worldBounds.width));

    canvas.drawParagraph(paragraph, worldBounds.topLeft);
  }
}

sealed class FeatureKind {
  const FeatureKind();
}

final class FeatureKindRectangle extends FeatureKind {
  const FeatureKindRectangle();
}

final class FeatureKindCircle extends FeatureKind {
  const FeatureKindCircle();
}

final class FeatureKindText extends FeatureKind {
  const FeatureKindText(this.contents);

  final String contents;
}
