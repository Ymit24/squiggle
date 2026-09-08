part of '../select_tool_3.dart';

class DuplicateState extends InteractionState {
  DuplicateState({
    required super.parent,
    required this._start,
    required this._selectedNodes,
    required this._originsAtDragStart,
    required this._selectionAlreadyMoved,
  });

  final Offset _start;
  final List<Node> _selectedNodes;
  final Map<NodeId, Offset> _originsAtDragStart;
  final bool _selectionAlreadyMoved;

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
    final clones = _selectedNodes
        .map((node) => node.copyWith(id: noId))
        .toList();

    for (final node in _selectedNodes) {
      node.origin = _originsAtDragStart[node.id]!;
    }
    context.document.addNodes(clones);
    context.selection.setSelection(clones.map((node) => node.id).toList());

    final state = TranslateState(
      parent: parent,
      start: _start,
      selectedNodes: clones,
      initialOrigins: {
        for (final node in clones)
          node.id: _selectionAlreadyMoved
              ? node.origin - totalMotion
              : node.origin,
      },
      hasDuplicated: true,
    );
    parent.transition(state, context);
    state.onPointerMove(
      context,
      cursorWorldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }
}
