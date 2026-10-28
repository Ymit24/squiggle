import 'package:flutter/painting.dart';

/// What a resize drag holds still and which kind of handle is being dragged.
///
/// Nodes receive it alongside the target bounds so that content which does not
/// stretch with its box, such as text, can still stay put where the user
/// expects.
class ResizeDrag {
  const ResizeDrag({required this.fixedPoint, required this.isCorner});

  /// The point of the node's bounds before the drag that stays in place.
  final Alignment fixedPoint;

  /// Whether a corner (scale) rather than a side (reflow) handle is dragged.
  final bool isCorner;
}
