import 'dart:math' as math;
import 'dart:ui';

import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node_id.dart';

sealed class NodeBinding {
  const NodeBinding(this.targetId);

  final NodeId targetId;

  Offset pointOn(Rect bounds);

  /// Resolves into the owner's parent coordinates; null keeps the fallback point.
  Offset? resolvePoint(Feature owner) {
    final target = owner.document?.featureById(targetId);
    if (target == null || target.kind is! BindingTargetCapable) return null;
    final bounds = (target.kind as BindingTargetCapable).bindingBoundsFor(
      target,
    );
    return pointOn(bounds) - (owner.parent?.globalOrigin ?? Offset.zero);
  }

  Map<String, dynamic> toJson();

  factory NodeBinding.fromJson(Map<String, dynamic> json) =>
      switch (json['type']) {
        'radial' => RadialBinding.fromJson(json),
        _ => throw FormatException('Unknown binding type: ${json['type']}'),
      };
}

final class RadialBinding extends NodeBinding {
  const RadialBinding(super.targetId, this.angle);

  final double angle;

  @override
  Offset pointOn(Rect bounds) {
    if (bounds.width == 0 && bounds.height == 0) return bounds.center;
    final direction = Offset(math.cos(angle), math.sin(angle));
    final x = direction.dx.abs() < 1e-12
        ? double.infinity
        : bounds.width / 2 / direction.dx.abs();
    final y = direction.dy.abs() < 1e-12
        ? double.infinity
        : bounds.height / 2 / direction.dy.abs();
    return bounds.center + direction * math.min(x, y);
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': 'radial',
    'targetId': targetId.value,
    'angle': angle,
  };

  factory RadialBinding.fromJson(Map<String, dynamic> json) => RadialBinding(
    NodeId.newId(json['targetId'] as int),
    (json['angle'] as num).toDouble(),
  );
}
