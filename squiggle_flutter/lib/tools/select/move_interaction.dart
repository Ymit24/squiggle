import 'dart:ui';

import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import 'select_interaction.dart';

Map<FeatureId, Offset> originsForFeatures(
  Document document,
  Iterable<FeatureId> ids,
) {
  return {
    for (final id in ids)
      if (document.featureById(id) case final feature?) id: feature.origin,
  };
}

/// Drags the selected features, optionally duplicating them with alt-drag.
class MoveInteraction extends SelectInteraction {
  MoveInteraction({
    required this.initialOrigins,
    required this.moveOffset,
    required this.pointerDownWorld,
    required this.isFirstTimeSelect,
    required this.draggedFeatureId,
    required this.originsAtDragStart,
    this.resumeEditing,
  });

  Map<FeatureId, Offset> initialOrigins;
  Offset moveOffset;
  final Offset pointerDownWorld;
  final bool isFirstTimeSelect;
  final FeatureId draggedFeatureId;
  final Map<FeatureId, Offset> originsAtDragStart;
  final FeatureId? resumeEditing;

  bool _didMove = false;
  bool _hasDuplicated = false;

  bool get didMove => _didMove;

  @override
  void update(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final document = context.document;
    final selection = context.selection;

    var effectiveMoveOffset = moveOffset;
    var effectiveHasDuplicated = _hasDuplicated;
    if (isAltPressed && !_hasDuplicated) {
      effectiveMoveOffset = _tryAltDuplicate(
        context,
        worldPosition,
        draggedFeatureId,
        originsAtDragStart,
        moveOffset,
        _didMove,
      );
      effectiveHasDuplicated = true;
    }
    moveOffset = effectiveMoveOffset;
    _hasDuplicated = effectiveHasDuplicated;
    if (_hasDuplicated) {
      initialOrigins = originsForFeatures(document, selection.selectedFeatures);
    }
    _didMove = true;

    final moveTarget = isShiftPressed
        ? constrainMoveToAxis(pointerDownWorld, worldPosition)
        : worldPosition;
    _moveSelectedFeatures(document, selection, moveTarget, moveOffset);
  }

  @override
  void commit(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (!_didMove) return;

    final document = context.document;
    final finalOrigins = <FeatureId, Offset>{};
    for (final id in initialOrigins.keys) {
      final feature = document.featureById(id);
      if (feature != null && feature.origin != initialOrigins[id]) {
        finalOrigins[id] = feature.origin;
      }
    }
    if (finalOrigins.isEmpty) return;

    context.record(MoveFeaturesCommand(initialOrigins, finalOrigins));
  }

  Offset _tryAltDuplicate(
    EditorContext context,
    Offset worldPosition,
    FeatureId draggedFeatureId,
    Map<FeatureId, Offset> originsAtDragStart,
    Offset moveOffset,
    bool draggedBeforeDuplicate,
  ) {
    final document = context.document;
    final selection = context.selection;
    final idsToDuplicate = selection.selectedFeatures.contains(draggedFeatureId)
        ? List<FeatureId>.of(selection.selectedFeatures)
        : [draggedFeatureId];

    final command = DuplicateFeaturesCommand(
      sourceIds: idsToDuplicate,
      originsAtDragStart: originsAtDragStart,
    );
    context.execute(command);

    final createdIds = command.createdIds;
    selection.setSelection(createdIds);

    final draggedIndex = idsToDuplicate.indexOf(draggedFeatureId);
    final draggedClone = document.featureById(createdIds[draggedIndex])!;
    selection.selectFeature(draggedClone.id);

    if (draggedBeforeDuplicate) {
      return worldPosition - draggedClone.origin;
    }
    return moveOffset;
  }

  void _moveSelectedFeatures(
    Document document,
    SelectionModel selection,
    Offset worldPosition,
    Offset moveOffset,
  ) {
    final ids = List<FeatureId>.of(selection.selectedFeatures);
    if (ids.isEmpty) return;

    final chaseFeature = document.featureById(ids.last);
    if (chaseFeature == null) return;

    final offsets = <FeatureId, Offset>{};
    for (final id in ids) {
      final feature = document.featureById(id);
      if (feature != null) {
        offsets[id] = feature.origin - chaseFeature.origin;
      }
    }

    final targets = <FeatureId, Offset>{};
    for (final entry in offsets.entries) {
      targets[entry.key] = worldPosition - moveOffset + entry.value;
    }
    document.moveFeatures(targets);
  }
}