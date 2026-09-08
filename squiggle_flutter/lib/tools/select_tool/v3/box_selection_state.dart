part of '../select_tool_3.dart';

class BoxSelectionState extends InteractionState {
  BoxSelectionState({
    required super.parent,
    required this._start,
    required this.isShift,
  }) {
    _current = _start;
  }

  final Offset _start;
  late Offset _current;
  final bool isShift;

  @override
  void onEnter(EditorContext context) {
    if (isShift) {
      return;
    }
    context.selection.setSelection([]);
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: box state move");
    _current = cursorWorldPosition;

    final selectionBounds = Rect.fromPoints(_start, _current);
    final selectedNodeIds = context.document.nodes
        .where((node) => node.intersectsRect(selectionBounds))
        .map((node) => node.id)
        .toList();

    if (isShiftPressed) {
      for (final id in selectedNodeIds) {
        context.selection.selectFeature(id);
      }
    } else {
      context.selection.setSelection(selectedNodeIds);
    }
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: box state up");
    parent.transition(IdleInteractionState(parent: parent), context);
  }

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    print("Box selection paint");
    final screenBounds = Rect.fromPoints(
      camera.worldToScreen(_start),
      camera.worldToScreen(_current),
    );
    final worldBounds = camera.screenToWorldBounds(screenBounds);
    SelectionPainter.paintMarquee(canvas, worldBounds);
  }
}
