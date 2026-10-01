import 'dart:ui';

import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/select_tool/duplicate_state.dart';
import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';

class TranslateState extends SelectInteractionState {
  TranslateState({
    required super.parent,
    required this._start,
    required this.selectedNodes,
    this._hasDuplicated = false,
  }) : _initialOrigins = {
         for (final node in selectedNodes) node.id: node.origin,
       },
       _originalNodes = {
         for (final node in selectedNodes) node.id: node.toDataModel(),
       };

  final Offset _start;
  final List<Node> selectedNodes;
  final Map<NodeId, Offset> _initialOrigins;
  final Map<NodeId, data.Node> _originalNodes;
  final bool _hasDuplicated;
  bool _detachedBindings = false;

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

    if (isAltPressed && !_hasDuplicated) {
      // A move may have detached bindings and rebased local geometry.
      for (final node in selectedNodes) {
        node.restoreFromDataModel(_originalNodes[node.id]!);
      }
      final state = DuplicateState(
        parent: parent,
        start: _start,
        selectedNodes: selectedNodes,
      );
      parent.transition(state, context);
      state.onPointerMove(
        context,
        worldPosition,
        camera,
        isShiftPressed: isShiftPressed,
        isAltPressed: isAltPressed,
      );
      return;
    }

    // Copying already detached external bindings; keep connections between
    // the copied nodes while translating the duplicated selection.
    if (!_detachedBindings && !_hasDuplicated && totalMotion != Offset.zero) {
      for (final node in selectedNodes) {
        if (node is Feature && node.kind is FeatureKindPolyline) {
          final kind = node.kind as FeatureKindPolyline;
          if (kind.bindings.isNotEmpty) {
            kind.detachBindings(node);
            _initialOrigins[node.id] = node.origin;
          }
        }
      }
      _detachedBindings = true;
    }

    for (var node in selectedNodes) {
      node.origin = _initialOrigins[node.id]! + totalMotion;
    }
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}
