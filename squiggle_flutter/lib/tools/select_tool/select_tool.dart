import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/select_tool/selection_painter.dart';
import 'package:squiggle_flutter/tools/tool.dart';
import 'package:squiggle_flutter/tools/select_tool/helpers.dart';
import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';

const kSelectionBoxPadding = 8.0;
const kSelectionHandleHitSize = 20.0;
const kSelectionHandlePaintSize = 12.0;
const kDoubleClickInterval = Duration(milliseconds: 300);

class SelectTool extends Tool {
  late InteractionState _activeInteractionState = IdleInteractionState(
    parent: this,
  );

  bool _hasTransaction = false;

  void beginTransaction(EditorContext context, String label, List<Node> nodes) {
    final container = nodes.first.parent;
    if (container == null ||
        nodes.any((node) => !identical(node.parent, container))) {
      throw StateError('Selected nodes must share a container');
    }
    context.history.begin(label, container: container);
    _hasTransaction = true;
    context.history.active.watch(nodes);
  }

  @override
  void cancelInteraction(EditorContext context) {
    _activeInteractionState = IdleInteractionState(parent: this);
    if (_hasTransaction) {
      context.history.cancel();
      _hasTransaction = false;

      // TODO: Move this somewhere else. we will need something like
      // this during normal undo/redo anyway.
      context.selection.setSelection(
        context.selection.selectedFeatures.where(
          (id) => context.document.nodeById(id) != null,
        ),
      );
    }
  }

  @override
  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    return _activeInteractionState.onKeyEvent(context, event);
  }

  void transition(InteractionState state, EditorContext context) {
    _activeInteractionState = state;
    _activeInteractionState.onEnter(context);
  }

  @override
  void deactivate(EditorContext context) {
    cancelInteraction(context);
    context.selection.clearSelection();
  }

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _activeInteractionState.onPointerDown(
      context,
      getTargetUnderCursor(context, worldPosition),
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );

    // TODO: Update how change detection works to not be bool response based.
    return true;
  }

  @override
  bool onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _activeInteractionState.onPointerMove(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    // TODO: Update how change detection works to not be bool response based.
    return true;
  }

  @override
  bool onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _activeInteractionState.onPointerUp(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    if (_hasTransaction) {
      context.history.commit();
      _hasTransaction = false;
    }
    // TODO: Update how change detection works to not be bool response based.
    return true;
  }

  @override
  bool onDoubleClick(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    _activeInteractionState.onDoubleClick(
      context,
      getTargetUnderCursor(context, worldPosition),
      worldPosition,
      camera,
    );
    return true;
  }

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    _activeInteractionState.paint(canvas, camera, context, imageRepository);

    SelectionPainter.paintSelectedFeatureBoxes(canvas, camera, context);
    SelectionPainter.paintSelectedPolylineHandles(canvas, camera, context);
  }

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    return _activeInteractionState.resolveCursor(
      context,
      worldPosition,
      camera,
    );
  }
}
