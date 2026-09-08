part of '../select_tool_3.dart';

class TranslateState extends InteractionState {
  TranslateState({
    required super.parent,
    required this._start,
    required this.selectedNodes,
    Map<NodeId, Offset>? initialOrigins,
    this._hasDuplicated = false,
  }) : _initialOrigins =
           initialOrigins ??
           {for (final node in selectedNodes) node.id: node.origin};

  final Offset _start;
  final List<Node> selectedNodes;
  final Map<NodeId, Offset> _initialOrigins;
  final bool _hasDuplicated;

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return EditorCursor.grabbing;
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final totalMotion = constrainedMoveDelta(
      _start,
      cursorWorldPosition,
      constrainToAxis: isShiftPressed,
    );

    if (isAltPressed && !_hasDuplicated) {
      final state = DuplicateState(
        parent: parent,
        start: _start,
        selectedNodes: selectedNodes,
        originsAtDragStart: _initialOrigins,
        selectionAlreadyMoved: true,
      );
      parent.transition(state, context);
      state.onPointerMove(
        context,
        cursorWorldPosition,
        camera,
        isShiftPressed: isShiftPressed,
        isAltPressed: isAltPressed,
      );
      return;
    }

    for (var node in selectedNodes) {
      node.origin = _initialOrigins[node.id]! + totalMotion;
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
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}
