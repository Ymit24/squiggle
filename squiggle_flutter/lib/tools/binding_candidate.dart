import 'dart:math' as math;
import 'dart:ui';

import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

/// A binding preview for the feature currently under the pointer.
class BindingCandidate {
  BindingCandidate._(this.target, this.binding);

  final Feature target;
  final RadialBinding binding;

  static BindingCandidate? at(Document document, Offset pointer) {
    final target = document.bindingTargetAt(pointer);
    if (target == null) return null;
    final delta =
        pointer -
        (target.kind as BindingTargetCapable).bindingBoundsFor(target).center;
    return BindingCandidate._(
      target,
      RadialBinding(target.id, math.atan2(delta.dy, delta.dx)),
    );
  }

  Rect get _bounds =>
      (target.kind as BindingTargetCapable).bindingBoundsFor(target);

  Offset get point => binding.pointOn(_bounds);

  void paint(Canvas canvas, Camera camera) {
    canvas.drawRect(
      _bounds.inflate(camera.screenLengthToWorldLength(4)),
      Paint()
        ..color = SquiggleColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = camera.screenLengthToWorldLength(2),
    );
  }
}
