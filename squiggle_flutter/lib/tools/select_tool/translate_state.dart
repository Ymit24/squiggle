import 'dart:ui';

import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_binding.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

import 'package:squiggle_flutter/tools/pointer_modifiers.dart';
import 'package:squiggle_flutter/tools/select_tool/duplicate_state.dart';
import 'package:squiggle_flutter/tools/select_tool/idle_interaction_state.dart';
import 'package:squiggle_flutter/tools/select_tool/interaction_state.dart';

class TranslateState extends SelectInteractionState {
  TranslateState({
    required super.parent,
    required this._start,
    required this.selectedNodes,
    Map<NodeId, Offset>? initialOrigins,
    this._hasDuplicated = false,
  }) : _initialOrigins =
           initialOrigins ??
           {for (final node in selectedNodes) node.id: node.origin},
       _snapshots = {
         for (final node in selectedNodes) node.id: node.toDataModel(),
       };

  final Offset _start;
  final List<Node> selectedNodes;
  final Map<NodeId, Offset> _initialOrigins;

  /// The selection before [onEnter] detached any line ends.
  final Map<NodeId, data.Node> _snapshots;
  final bool _hasDuplicated;

  /// Moving a line detaches the ends whose targets stay behind.
  @override
  void onEnter(EditorContext context) {
    final moving = selectedNodes.map((node) => node.id).toSet();
    bool movesAlong(NodeId targetId) =>
        switch (context.document.nodeById(targetId)) {
          final target? => isWithin(target, moving),
          null => false,
        };
    for (final node in selectedNodes) {
      if (node case Feature(kind: BindingCapable kind)) {
        kind.unbind(node, keep: movesAlong);
      }
    }
  }

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
    required PointerModifiers modifiers,
  }) {
    final totalMotion = constrainedMoveDelta(
      _start,
      worldPosition,
      constrainToAxis: modifiers.shift,
    );

    if (modifiers.alt && !_hasDuplicated) {
      final state = DuplicateState(
        parent: parent,
        start: _start,
        selectedNodes: selectedNodes,
        snapshotsAtDragStart: _snapshots,
        selectionAlreadyMoved: true,
      );
      parent.transition(state, context);
      state.onPointerMove(context, worldPosition, camera, modifiers: modifiers);
      return;
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
    required PointerModifiers modifiers,
  }) {
    parent.transition(IdleInteractionState(parent: parent), context);
  }
}
