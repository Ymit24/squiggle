import 'dart:ui';

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
