import 'dart:math';

import 'package:data_models/data_models.dart' as data;
import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/models/feature_kinds/feature_kind.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

export 'feature_kinds/feature_kind.dart';
export 'fill_type.dart';
export 'font_size_preset.dart';
export 'line_end_cap.dart';
export 'stroke_type.dart';
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
    final FeatureKind kind = switch (content['type']) {
      'rectangle' => FeatureKindRectangle.fromDataModel(content),
      'circle' => FeatureKindCircle.fromDataModel(content),
      'text' => FeatureKindText.fromDataModel(content),
      'polyline' => FeatureKindPolyline.fromDataModel(content),
      'image' => FeatureKindImage.fromDataModel(content),
      _ => throw FormatException('Unknown feature kind: ${content['type']}'),
    };

    return Feature(
      id: NodeId.newId(raw.id),
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
  data.Feature toDataModel() {
    return data.Feature(
      id: id.value,
      originX: origin.dx,
      originY: origin.dy,
      width: size.width,
      height: size.height,
      content: kind.toDataModel(),
    );
  }

  @override
  void restoreFromDataModel(data.Node raw) {
    if (raw is! data.Feature || raw.id != id.value) {
      throw ArgumentError.value(raw, 'raw', 'Feature snapshot does not match');
    }
    final restored = Feature.fromDataModel(raw);
    origin = restored.origin;
    size = restored.size;
    kind = restored.kind;
  }

  @override
  Rect localBounds() => kind.boundsFor(this);

  @override
  void resize(Rect bounds) => kind.applyBounds(this, bounds);

  void setBounds(Rect bounds) {
    origin = bounds.topLeft;
    size = bounds.size;
  }

  @override
  bool hitTest(Offset worldPoint) {
    final centerOrigin = center();
    final worldInCenterSpace = worldPoint - centerOrigin;

    final c = cos(-localRotationAngle * pi / 180);
    final s = sin(-localRotationAngle * pi / 180);

    final rotatedWorldPointInCenterSpace = Offset(
      worldInCenterSpace.dx * c - worldInCenterSpace.dy * s,
      worldInCenterSpace.dx * s + worldInCenterSpace.dy * c,
    );

    final localRotatedPoint = rotatedWorldPointInCenterSpace;

    return kind.hitTest(this, localRotatedPoint);
  }

  // NOTE: use SAT to check if selection rectangle and rotated feature kind intersect.
  // https://programmerart.weebly.com/separating-axis-theorem.html
  @override
  bool intersectsRect(Rect rect) => kind.intersectsRect(this, rect);

  @override
  Feature copyWith({
    NodeId? id,
    Offset? origin,
    Size? size,
    FeatureKind? kind,
  }) => Feature(
    id: id ?? this.id,
    origin: origin ?? this.origin,
    size: size ?? this.size,
    kind: (kind ?? this.kind).clone(),
  );

  @override
  void paint(Canvas canvas, ImageRepository imageRepository) {
    canvas.save();
    final centerOrigin = center();
    canvas.translate(centerOrigin.dx, centerOrigin.dy);
    canvas.rotate(localRotationAngle * pi / 180);
    kind.paint(this, canvas, imageRepository);
    canvas.restore();
  }
}
