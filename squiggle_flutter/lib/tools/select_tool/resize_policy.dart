import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';

/// How the select tool lets a node be resized.
class ResizePolicy {
  const ResizePolicy({
    this.verticalSides = true,
    this.lockCornerAspect = false,
  });

  static const free = ResizePolicy();

  /// Text height follows its contents: sides only change the wrap width and
  /// corners scale it uniformly.
  static const text = ResizePolicy(
    verticalSides: false,
    lockCornerAspect: true,
  );

  /// Groups holding text scale it uniformly from corners too. A free corner
  /// would flip that text between scaling and reflowing whenever the drag
  /// crossed the starting height.
  static const containsText = ResizePolicy(lockCornerAspect: true);

  /// Whether the top and bottom handles are offered.
  final bool verticalSides;

  /// Whether corner drags keep the aspect ratio without Shift.
  final bool lockCornerAspect;

  static ResizePolicy of(Node node) => switch (node) {
    Feature(kind: FeatureKindText()) => text,
    Group(:final children)
        when children.any((child) => of(child).lockCornerAspect) =>
      containsText,
    _ => free,
  };
}
