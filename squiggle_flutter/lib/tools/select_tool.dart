import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/select/edit_point_interaction.dart';
import 'package:squiggle_flutter/tools/select/marquee_interaction.dart';
import 'package:squiggle_flutter/tools/select/move_interaction.dart';
import 'package:squiggle_flutter/tools/select/resize_interaction.dart';
import 'package:squiggle_flutter/tools/select/select_hit_test.dart';
import 'package:squiggle_flutter/tools/select/select_interaction.dart';
import 'package:squiggle_flutter/tools/select/select_overlay.dart';
import 'package:squiggle_flutter/tools/select/select_resize_geometry.dart';
import 'package:squiggle_flutter/tools/tool.dart';

export 'select/select_hit_test.dart'
    show kSelectionBoxPadding, kSelectionHandleHitSize, selectionBoxWorldBounds;

const kDoubleClickInterval = Duration(milliseconds: 300);

/// Persistent Select-tool mode, separate from any transient pointer
/// interaction.
sealed class SelectMode {
  const SelectMode();
}

final class SelectModeNormal extends SelectMode {
  const SelectModeNormal();
}

final class SelectModeEditing extends SelectMode {
  const SelectModeEditing(this.featureId);

  final FeatureId featureId;
}

/// Routes Select-mode input to the right interaction and coordinates
/// selection, editing mode, and the Select overlay.
///
/// The details of moving, resizing, marquee selection, and point editing live
/// in their respective [SelectInteraction]s; hit testing lives in
/// [SelectHitTester]; rendering lives in [SelectOverlay]; resize math lives in
/// the select_resize_geometry module.
class SelectTool extends Tool {
  SelectTool()
    : _mode = const SelectModeNormal(),
      _interaction = null;

  static const SelectHitTester _hitTester = SelectHitTester();
  static const SelectOverlay _overlay = SelectOverlay();

  SelectMode _mode;
  SelectInteraction? _interaction;
  FeatureId? _lastTapFeatureId;
  DateTime? _lastTapTime;

  FeatureId? get _editingFeatureId => switch (_mode) {
    SelectModeNormal() => null,
    SelectModeEditing(:final featureId) => featureId,
  };

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    _overlay.paint(
      canvas,
      camera,
      context,
      interaction: _interaction,
      editingFeatureId: _editingFeatureId,
    );
  }

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    final interaction = _interaction;
    if (interaction != null) {
      switch (interaction) {
        case MoveInteraction():
        case EditPointInteraction():
          return EditorCursor.grabbing;
        case ResizeInteraction(:final handle):
          return _cursorForResizeHandle(handle);
        case MarqueeInteraction():
          break;
      }
    }

    final hit = _hitTester.hitTest(
      document: context.document,
      selection: context.selection,
      worldPoint: worldPosition,
      camera: camera,
      editingFeatureId: _editingFeatureId,
    );
    return switch (hit) {
      FeatureHit() ||
      SelectionBoxHit() ||
      PolylineVertexHit() => EditorCursor.grab,
      ResizeHandleHit(:final handle) => _cursorForResizeHandle(handle),
      EmptyHit() => EditorCursor.basic,
    };
  }

  @override
  void deactivate(EditorContext context) {
    _interaction?.cancel(context);
    _interaction = null;
    _mode = const SelectModeNormal();
    context.selection.clearSelection();
    _lastTapFeatureId = null;
    _lastTapTime = null;
  }

  @override
  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    if (_interaction != null) return false;
    if (_mode is! SelectModeEditing) return false;
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    _mode = const SelectModeNormal();
    return true;
  }

  @override
  void onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final hit = _hitTester.hitTest(
      document: context.document,
      selection: context.selection,
      worldPoint: worldPosition,
      camera: camera,
      editingFeatureId: _editingFeatureId,
    );
    switch (hit) {
      case PolylineVertexHit(:final featureId, :final pointIndex):
        _beginEditPoint(context, worldPosition, featureId, pointIndex);
      case ResizeHandleHit(:final handle):
        _beginResize(context, worldPosition, handle);
      case FeatureHit(:final featureId):
        _beginMove(context, worldPosition, featureId, isShiftPressed);
      case SelectionBoxHit():
      case EmptyHit():
        _beginMarquee(context, worldPosition, isShiftPressed);
    }
  }

  @override
  void onPointerMove(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final interaction = _interaction;
    if (interaction == null) return;
    interaction.update(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final interaction = _interaction;
    if (interaction == null) return;
    interaction.commit(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    _handleInteractionEnd(
      context,
      worldPosition,
      camera,
      interaction,
      isShiftPressed,
    );
    _interaction = null;
  }

  void _beginEditPoint(
    EditorContext context,
    Offset worldPosition,
    FeatureId featureId,
    int pointIndex,
  ) {
    final feature = context.document.featureById(featureId)!;
    final kind = feature.kind as FeatureKindPolyline;
    final points = worldPoints(feature.origin, kind.localPoints);
    _interaction = EditPointInteraction(
      featureId: featureId,
      pointIndex: pointIndex,
      dragOffset: worldPosition - points[pointIndex],
      initialOrigin: feature.origin,
      initialLocalPoints: List.of(kind.localPoints),
    );
  }

  void _beginResize(
    EditorContext context,
    Offset worldPosition,
    SelectionResizeHandle handle,
  ) {
    final document = context.document;
    final selection = context.selection;
    final selectedId = selection.selectedFeatures.single;
    final selected = document.featureById(selectedId)!;

    final bounds = selected.bounds();
    _interaction = ResizeInteraction(
      featureId: selectedId,
      handle: handle,
      anchor: anchorForResizeHandle(handle, bounds),
      initialBounds: bounds,
      resizeOffset: worldPosition - referencePointForResizeHandle(handle, bounds),
      resumeEditing: _editingFeatureId,
    );
  }

  void _beginMove(
    EditorContext context,
    Offset worldPosition,
    FeatureId featureId,
    bool isShiftPressed,
  ) {
    final document = context.document;
    final selection = context.selection;

    final editingFeatureId = _editingFeatureId;
    if (editingFeatureId != null && featureId != editingFeatureId) {
      _mode = const SelectModeNormal();
    }

    final didSelect = !selection.isFeatureSelected(featureId);
    if (!isShiftPressed && !selection.isFeatureSelected(featureId)) {
      selection.clearSelection();
    }
    selection.selectFeature(featureId);

    final resumeEditing = editingFeatureId != null && featureId == editingFeatureId
        ? editingFeatureId
        : null;

    final feature = document.featureById(featureId)!;
    _interaction = MoveInteraction(
      initialOrigins: originsForFeatures(document, selection.selectedFeatures),
      moveOffset: worldPosition - feature.origin,
      pointerDownWorld: worldPosition,
      isFirstTimeSelect: didSelect,
      draggedFeatureId: featureId,
      originsAtDragStart: originsForFeatures(
        document,
        selection.selectedFeatures,
      ),
      resumeEditing: resumeEditing,
    );
  }

  void _beginMarquee(
    EditorContext context,
    Offset worldPosition,
    bool isShiftPressed,
  ) {
    if (_editingFeatureId != null) {
      _mode = const SelectModeNormal();
    }
    _interaction = MarqueeInteraction(start: worldPosition, end: worldPosition);
    if (!isShiftPressed) {
      context.selection.clearSelection();
    }
  }

  void _handleInteractionEnd(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
    SelectInteraction interaction,
    bool isShiftPressed,
  ) {
    switch (interaction) {
      case MoveInteraction():
        _handleMoveEnd(context, worldPosition, camera, interaction, isShiftPressed);
      case ResizeInteraction(:final resumeEditing):
        if (resumeEditing != null) {
          _mode = SelectModeEditing(resumeEditing);
        }
      case EditPointInteraction(:final featureId):
        _mode = SelectModeEditing(featureId);
      case MarqueeInteraction():
        break;
    }
  }

  void _handleMoveEnd(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
    MoveInteraction interaction,
    bool isShiftPressed,
  ) {
    final document = context.document;
    final selection = context.selection;

    final hovered = document.featureAtPoint(worldPosition);
    if (hovered != null && !interaction.didMove) {
      final now = DateTime.now();
      if (_lastTapFeatureId == hovered.id &&
          _lastTapTime != null &&
          now.difference(_lastTapTime!) <= kDoubleClickInterval) {
        if (!isShiftPressed) {
          selection.clearSelection();
          selection.selectFeature(hovered.id);
        }
        if (hovered.kind is FeatureKindText) {
          final textKind = hovered.kind as FeatureKindText;
          context.startTextEdit(
            EditTextEditSession(
              featureId: hovered.id,
              initialContents: textKind.contents,
              canvasLocalBounds: camera.worldToScreenBounds(hovered.bounds()),
            ),
          );
          _mode = const SelectModeNormal();
          _lastTapFeatureId = null;
          _lastTapTime = null;
          return;
        }
        _mode = SelectModeEditing(hovered.id);
        _lastTapFeatureId = null;
        _lastTapTime = null;
        return;
      }
      _lastTapFeatureId = hovered.id;
      _lastTapTime = now;

      if (isShiftPressed) {
        if (!interaction.isFirstTimeSelect) {
          selection.deselectFeature(hovered.id);
        }
      } else {
        selection.clearSelection();
        selection.selectFeature(hovered.id);
      }
    }

    final resumeEditing = interaction.resumeEditing;
    _mode = resumeEditing != null
        ? SelectModeEditing(resumeEditing)
        : const SelectModeNormal();
  }

  EditorCursor _cursorForResizeHandle(SelectionResizeHandle handle) {
    return switch (handle) {
      SelectionResizeHandle.topLeft => EditorCursor.resizeUpLeft,
      SelectionResizeHandle.top => EditorCursor.resizeUp,
      SelectionResizeHandle.topRight => EditorCursor.resizeUpRight,
      SelectionResizeHandle.right => EditorCursor.resizeRight,
      SelectionResizeHandle.bottomRight => EditorCursor.resizeDownRight,
      SelectionResizeHandle.bottom => EditorCursor.resizeDown,
      SelectionResizeHandle.bottomLeft => EditorCursor.resizeDownLeft,
      SelectionResizeHandle.left => EditorCursor.resizeLeft,
    };
  }
}