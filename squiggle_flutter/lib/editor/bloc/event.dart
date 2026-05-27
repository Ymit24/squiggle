import 'dart:ui';

abstract class EditorEvent {
  const EditorEvent();
}

class PointerDownAtWorldEvent extends EditorEvent {
  const PointerDownAtWorldEvent({
    required this.worldPosition,
    required this.isShiftPressed,
  });

  final Offset worldPosition;
  final bool isShiftPressed;
}
