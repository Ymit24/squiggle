import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'duplicate_state.dart';
import 'idle_interaction_state.dart';
import 'interaction_state.dart';
import 'translate_state.dart';

class ClickNodeState extends InteractionState {
  ClickNodeState({
    required super.parent,
    required this._start,
    required this._chase,
    required this.selectedNodes,
    required this.isShiftPressed,
  });

  final Offset _start;
  final Node _chase;
  final List<Node> selectedNodes;
  final bool isShiftPressed;
  late final bool _wasSelected = selectedNodes.any(
    (node) => node.id == _chase.id,
  );

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return EditorCursor.grabbing;
  }

  @override
  void onEnter(EditorContext context) {
    if (_wasSelected) {
      return;
    }

    if (isShiftPressed) {
      context.selection.selectFeature(_chase.id);
      selectedNodes.add(_chase);
    } else {
      context.selection.setSelection([_chase.id]);
      selectedNodes
        ..clear()
        ..add(_chase);
    }
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: click state move");
    if (selectedNodes.isNotEmpty) {
      parent.beginTransaction(
        context,
        isAltPressed ? 'Duplicate selection' : 'Move selection',
        selectedNodes,
      );
      final state = isAltPressed
          ? DuplicateState(
              parent: parent,
              start: _start,
              selectedNodes: selectedNodes,
              originsAtDragStart: {
                for (final node in selectedNodes) node.id: node.origin,
              },
              selectionAlreadyMoved: false,
            )
          : TranslateState(
              parent: parent,
              selectedNodes: selectedNodes,
              start: _start,
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

  @override
  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    print("D: click state up");
    if (isShiftPressed) {
      if (_wasSelected) {
        context.selection.deselectFeature(_chase.id);
      }
    } else {
      context.selection.setSelection([_chase.id]);
    }
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}
