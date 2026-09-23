import 'package:flutter/widgets.dart';
import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/models/feature_kinds/feature_kind.dart';

export 'feature_kinds/feature_kind.dart';
export 'font_size_preset.dart';
export 'line_end_cap.dart';
export 'stroke_width_preset.dart';
export 'text_alignment.dart';

/// A drawable shape or label in world space.
class Feature extends Node {
  // Keep the public argument named size while the field remains private.
  Feature({
    super.id,
    required super.origin,
    required Size size,
    required this.kind,
    // ignore: prefer_initializing_formals
  }) : _size = size;

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
    editGeometry((edit) {
      edit.origin = restored.origin;
      edit.size = restored.size;
    });
    kind = restored.kind;
  }

  Size _size;
  Size get size => _size;
  FeatureKind kind;

  @override
  NodeGeometryEdit createGeometryEdit() => NodeGeometryEdit(origin, size: size);

  @override
  void commitGeometryEdit(NodeGeometryEdit edit) {
    super.commitGeometryEdit(edit);
    _size = edit.size!;
  }

  double get width => size.width;

  double get height => size.height;

  @override
  Rect localBounds() => kind.boundsFor(this);

  @override
  void resize(Rect bounds) => kind.applyBounds(this, bounds);

  void setBounds(Rect bounds) => editGeometry((edit) {
    edit.origin = bounds.topLeft;
    edit.size = bounds.size;
  });

  @override
  bool hitTest(Offset worldPoint) => kind.hitTest(this, worldPoint);

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
  void paint(Canvas canvas, ImageRepository imageRepository) =>
      kind.paint(this, canvas, imageRepository);
}
