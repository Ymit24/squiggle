import 'package:flutter/foundation.dart';

/// Modifier keys held during a pointer event.
@immutable
class PointerModifiers {
  const PointerModifiers({
    this.shift = false,
    this.alt = false,
    this.command = false,
  });

  static const none = PointerModifiers();

  /// Constrains the gesture: axis lock, 45° angles, fixed aspect ratio.
  final bool shift;

  /// Alternate gesture: duplicate while dragging, resize symmetrically.
  final bool alt;

  /// Ctrl or Cmd: place freely instead of snapping to other nodes.
  final bool command;
}
