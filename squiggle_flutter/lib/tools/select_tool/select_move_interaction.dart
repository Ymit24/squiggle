import 'dart:ui';

import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/tools/editor_interaction.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

/// Select-tool interaction for dragging a selected polyline vertex.
class SelectMoveInteraction extends EditorInteraction {
  Map<FeatureId, Offset>? _initialOrigins;
  Map<FeatureId, Offset>? _originsAtDragStart;
  Offset? _moveOffset;
  Offset? _pointerDownWorld;
  FeatureId? _draggedFeatureId;
  bool _isFirstTimeSelect = false;
  bool _hasDuplicated = false;
  bool _didMove = false;
  FeatureId? _lastTapFeatureId;
  DateTime? _lastTapTime;

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final feature = context.document.featureAtPoint(worldPosition);
    if (feature == null) return false;
    final selection = context.selection;
    final isFirstTimeSelect = !selection.isFeatureSelected(feature.id);
    if (!selection.isFeatureSelected(feature.id)) {
      if (!isShiftPressed) selection.clearSelection();
      selection.selectFeature(feature.id);
    }
    _initialOrigins = {
      for (final id in selection.selectedFeatures)
        if (context.document.featureById(id) case final f?) id: f.origin,
    };
    _moveOffset = worldPosition - feature.origin;
    _pointerDownWorld = worldPosition;
    _draggedFeatureId = feature.id;
    _isFirstTimeSelect = isFirstTimeSelect;
    _hasDuplicated = false;
    _originsAtDragStart = _captureOrigins(
      context.document,
      selection.selectedFeatures,
    );
    _didMove = false;
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
    final origins = _initialOrigins;
    final offset = _moveOffset;
    final down = _pointerDownWorld;
    if (origins == null || offset == null || down == null) return false;
    final ids = List<FeatureId>.of(context.selection.selectedFeatures);
    if (ids.isEmpty) return false;
    final chase = context.document.featureById(ids.last);
    if (chase == null) return false;
    final target = isShiftPressed
        ? constrainMoveToAxis(down, worldPosition)
        : worldPosition;

    if (isAltPressed && !_hasDuplicated) {
      final draggedId = _draggedFeatureId;
      final originsAtDragStart = _originsAtDragStart;
      if (draggedId != null && originsAtDragStart != null) {
        _moveOffset = _duplicateSelection(
          context,
          worldPosition,
          draggedId,
          originsAtDragStart,
          offset,
          _didMove,
        );
        _initialOrigins = _captureOrigins(
          context.document,
          context.selection.selectedFeatures,
        );
        _hasDuplicated = true;
      }
    }

    final effectiveOffset = _moveOffset!;
    final offsets = <FeatureId, Offset>{};
    for (final id in ids) {
      final feature = context.document.featureById(id);
      if (feature != null) offsets[id] = feature.origin - chase.origin;
    }
    var changed = false;
    for (final entry in offsets.entries) {
      final id = entry.key;
      final feature = context.document.featureById(id);
      if (feature != null) {
        final next = target - effectiveOffset + entry.value;
        if (feature.origin != next) {
          feature.origin = next;
          changed = true;
        }
      }
    }
    if (changed) context.notifyViewportChanged();
    _didMove = true;
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
    final initial = _initialOrigins;
    if (_didMove && initial != null) {
      final finalOrigins = {
        for (final id in initial.keys)
          if (context.document.featureById(id) case final f?) id: f.origin,
      };
      if (finalOrigins.isNotEmpty) {
        context.record(MoveFeaturesCommand(initial, finalOrigins));
      }
    } else {
      final hovered = context.document.featureAtPoint(worldPosition);
      if (hovered != null && !_didMove) {
        final now = DateTime.now();
        if (_lastTapFeatureId == hovered.id &&
            _lastTapTime != null &&
            now.difference(_lastTapTime!) <= kDoubleClickInterval) {
          if (!isShiftPressed) {
            context.selection.clearSelection();
            context.selection.selectFeature(hovered.id);
          }
          if (hovered.kind is FeatureKindText) {
            final text = hovered.kind as FeatureKindText;
            context.startTextEdit(
              EditTextEditSession(
                featureId: hovered.id,
                initialContents: text.contents,
                canvasLocalBounds: camera.worldToScreenBounds(hovered.bounds()),
              ),
            );
            _lastTapFeatureId = null;
            _lastTapTime = null;
            _clearGesture();
            return true;
          }
        }
        _lastTapFeatureId = hovered.id;
        _lastTapTime = now;
        if (isShiftPressed) {
          if (!_isFirstTimeSelect) {
            context.selection.deselectFeature(hovered.id);
          }
        } else {
          context.selection.clearSelection();
          context.selection.selectFeature(hovered.id);
        }
      }
    }
    _clearGesture();
    return true;
  }

  void _clearGesture() {
    _initialOrigins = null;
    _originsAtDragStart = null;
    _moveOffset = null;
    _pointerDownWorld = null;
    _draggedFeatureId = null;
    _isFirstTimeSelect = false;
    _hasDuplicated = false;
    _didMove = false;
  }

  @override
  void deactivate(EditorContext context) {
    _clearGesture();
    _lastTapFeatureId = null;
    _lastTapTime = null;
  }

  Map<FeatureId, Offset> _captureOrigins(
    Document document,
    List<FeatureId> ids,
  ) => {
    for (final id in ids)
      if (document.featureById(id) case final feature?) id: feature.origin,
  };

  Offset _duplicateSelection(
    EditorContext context,
    Offset worldPosition,
    FeatureId draggedFeatureId,
    Map<FeatureId, Offset> originsAtDragStart,
    Offset moveOffset,
    bool draggedBeforeDuplicate,
  ) {
    final selection = context.selection;
    final ids = selection.selectedFeatures.contains(draggedFeatureId)
        ? List<FeatureId>.of(selection.selectedFeatures)
        : [draggedFeatureId];
    final command = DuplicateFeaturesCommand(
      sourceIds: ids,
      originsAtDragStart: originsAtDragStart,
    );
    context.execute(command);
    selection.setSelection(command.createdIds);
    final draggedIndex = ids.indexOf(draggedFeatureId);
    final clone = context.document.featureById(
      command.createdIds[draggedIndex],
    )!;
    return draggedBeforeDuplicate ? worldPosition - clone.origin : moveOffset;
  }
}
