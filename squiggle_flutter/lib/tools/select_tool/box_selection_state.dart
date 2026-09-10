import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/select_tool/selection_painter.dart';

import 'idle_interaction_state.dart';
import 'interaction_state.dart';

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
    _current = cursorWorldPosition;

    final selectionBounds = Rect.fromPoints(_start, _current);
    final selectedNodeIds = context.document.nodes
        .where((node) => node.intersectsRect(selectionBounds))
        .map((node) => node.id)
        .toList();

    print(
      "D: $selectedNodeIds. Current selection: ${context.selection.selectedNodes}",
    );

    if (isShiftPressed) {
      for (final id in selectedNodeIds) {
        context.selection.selectNode(id);
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
    parent.transition(IdleInteractionState(parent: parent), context);
  }

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    final screenBounds = Rect.fromPoints(
      camera.worldToScreen(_start),
      camera.worldToScreen(_current),
    );
    final worldBounds = camera.screenToWorldBounds(screenBounds);
    SelectionPainter.paintMarquee(canvas, worldBounds);
  }
}
