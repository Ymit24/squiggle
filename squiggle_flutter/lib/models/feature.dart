import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

import 'feature_id.dart';
import 'feature_kinds/feature_kind.dart';

export 'feature_kinds/feature_kind.dart';
export 'font_size_preset.dart';
export 'stroke_width_preset.dart';
export 'text_alignment.dart';

/// A drawable shape or label in world space.
class Feature {
  Feature({
    this.id = noId,
    required this.origin,
    required this.size,
    required this.kind,
  });

  FeatureId id;
  Offset origin;
  Size size;
  FeatureKind kind;

  double get width => size.width;

  double get height => size.height;

  Rect bounds() => kind.boundsFor(this);

  void setBounds(Rect bounds) => kind.applyBounds(this, bounds);

  void setBoundsDirect(Rect bounds) {
    origin = bounds.topLeft;
    size = bounds.size;
  }

  bool hitTest(Offset worldPoint) => kind.hitTest(this, worldPoint);

  bool intersectsRect(Rect rect) => kind.intersectsRect(this, rect);

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

  void paint(Canvas canvas, ImageRepository imageRepository) =>
      kind.paint(this, canvas, imageRepository);
}
