import 'package:flutter/widgets.dart';
import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

import 'feature_id.dart';
import 'feature_kinds/feature_kind.dart';

export 'feature_kinds/feature_kind.dart';
export 'font_size_preset.dart';
export 'stroke_width_preset.dart';
export 'text_alignment.dart';

/// A drawable shape or label in world space.
class Feature extends Node {
  Feature({
    super.id,
    required super.origin,
    required this.size,
    required this.kind,
  });

  factory Feature.fromDataModel(data.Feature raw) {
    final content = raw.content;
    final kind = switch (content['type']) {
      'rectangle' => FeatureKindRectangle.fromDataModel(content),
      'circle' => FeatureKindCircle.fromDataModel(content),
      'text' => FeatureKindText.fromDataModel(content),
      'polyline' => FeatureKindPolyline.fromDataModel(content),
      'image' => FeatureKindImage.fromDataModel(content),
      _ => throw FormatException('Unknown feature kind: ${content['type']}'),
    };

    return Feature(
      id: FeatureId.newId(raw.id),
      origin: Offset(raw.originX, raw.originY),
      size: Size(raw.width, raw.height),
      kind: kind,
    );
  }

  Size size;
  FeatureKind kind;

  double get width => size.width;

  double get height => size.height;

  @override
  Rect bounds() => kind.boundsFor(this);

  @override
  void resize(Rect bounds) => kind.applyBounds(this, bounds);

  void setBounds(Rect bounds) {
    origin = bounds.topLeft;
    size = bounds.size;
  }

  bool hitTest(Offset worldPoint) => kind.hitTest(this, worldPoint);

  @override
  bool intersectsRect(Rect rect) => kind.intersectsRect(this, rect);

  Offset center() => bounds().center;

  void moveTo(Offset newOrigin) {
    origin = newOrigin;
  }

  void setKind(FeatureKind newKind, {Size? newSize}) {
    if (newSize != null) size = newSize;
    kind = newKind;
  }

  @override
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

  @override
  void paint(Canvas canvas, ImageRepository imageRepository) =>
      kind.paint(this, canvas, imageRepository);
}
