import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/pointer_modifiers.dart';
import 'package:squiggle_flutter/tools/select_tool/duplicate_state.dart';
import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/translate_state.dart';

class ClickNodeState extends SelectInteractionState {
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
      context.selection.selectNode(_chase.id);
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
    Offset worldPosition,
    Camera camera, {
    required PointerModifiers modifiers,
  }) {
    if (selectedNodes.isNotEmpty) {
      parent.beginTransaction(
        context,
        modifiers.alt ? 'Duplicate selection' : 'Move selection',
        selectedNodes,
      );
      final state = modifiers.alt
          ? DuplicateState(
              parent: parent,
              start: _start,
              selectedNodes: selectedNodes,
              snapshotsAtDragStart: {
                for (final node in selectedNodes) node.id: node.toDataModel(),
              },
              selectionAlreadyMoved: false,
            )
          : TranslateState(
              parent: parent,
              selectedNodes: selectedNodes,
              start: _start,
            );
      parent.transition(state, context);
      state.onPointerMove(context, worldPosition, camera, modifiers: modifiers);
    }
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required PointerModifiers modifiers,
  }) {
    if (modifiers.shift) {
      if (_wasSelected) {
        context.selection.deselectNode(_chase.id);
      }
    } else {
      context.selection.setSelection([_chase.id]);
    }
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}
