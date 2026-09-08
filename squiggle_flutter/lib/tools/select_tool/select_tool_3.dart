import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/selection_painter.dart';
import 'package:squiggle_flutter/tools/tool.dart';

part 'v3/helpers.dart';
part 'v3/interaction_state.dart';
part 'v3/hit_target.dart';
part 'v3/idle_interaction_state.dart';
part 'v3/drag_polyline_handle_state.dart';
part 'v3/resize_state.dart';
part 'v3/box_selection_state.dart';
part 'v3/click_canvas_state.dart';
part 'v3/click_node_state.dart';
part 'v3/duplicate_state.dart';
part 'v3/translate_state.dart';
part 'v3/resize_handle.dart';
part 'v3/polyline_handle.dart';
part 'v3/polyline_handle_util.dart';
part 'v3/resize_handle_util.dart';

class SelectTool3 extends Tool {
  late InteractionState _activeInteractionState = IdleInteractionState(
    parent: this,
  );

  void transition(InteractionState state, EditorContext context) {
    _activeInteractionState = state;
    _activeInteractionState.onEnter(context);
  }

  @override
  void deactivate(EditorContext context) {
    _activeInteractionState = IdleInteractionState(parent: this);
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
