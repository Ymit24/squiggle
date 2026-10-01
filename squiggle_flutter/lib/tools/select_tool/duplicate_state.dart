import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/services/duplicate_nodes.dart';

import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/translate_state.dart';

class DuplicateState extends SelectInteractionState {
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
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final totalMotion = constrainedMoveDelta(
      _start,
      worldPosition,
      constrainToAxis: isShiftPressed,
    );
    final clones = duplicateNodes(
      nodes: _selectedNodes,
      transaction: context.history.active,
      selection: context.selection,
    );

    for (final node in _selectedNodes) {
      node.origin = _originsAtDragStart[node.id]!;
    }

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
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }
}
