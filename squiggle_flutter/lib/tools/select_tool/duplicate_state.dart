import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/services/duplicate_nodes.dart';

import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/translate_state.dart';

class DuplicateState extends SelectInteractionState {
  DuplicateState({
    required super.parent,
    required this._start,
    required this._selectedNodes,
  });

  final Offset _start;
  final List<Node> _selectedNodes;

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final clones = duplicateNodes(
      nodes: _selectedNodes,
      transaction: context.history.active,
      selection: context.selection,
    );

    final state = TranslateState(
      parent: parent,
      start: _start,
      selectedNodes: clones,
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
