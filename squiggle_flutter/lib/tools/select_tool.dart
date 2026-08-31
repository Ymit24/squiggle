import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';
import 'package:squiggle_flutter/utils/painting.dart';

const kSelectionBoxPadding = 8.0;
const kSelectionHandleHitSize = 20.0;
const kSelectionHandlePaintSize = 12.0;
const kDoubleClickInterval = Duration(milliseconds: 300);

enum SelectionResizeHandle {
  topLeft,
  top,
  topRight,
  right,
  bottomRight,
  bottom,
  bottomLeft,
  left,
}

Rect selectionBoxWorldBounds(Rect featureBounds) {
  return featureBounds.inflate(kSelectionBoxPadding);
}

class SelectTool extends Tool {
  SelectTool() : _state = const _Idle();

  _SelectState _state;
  FeatureId? _lastTapFeatureId;
  DateTime? _lastTapTime;

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    final document = context.document;

    for (final featureId in context.selection.selectedFeatures) {
      final feature = document.featureById(featureId);
      if (feature != null) {
        _paintSelectionBox(canvas, camera, feature.bounds());
      }
    }

    final selectedPolyline = _selectedPolyline(document, context.selection);
    if (selectedPolyline != null) {
      final kind = selectedPolyline.kind as FeatureKindPolyline;
      for (final point in worldPoints(
        selectedPolyline.origin,
        kind.localPoints,
      )) {
        _paintHandle(canvas, camera, point);
      }
    }

    final state = _state;
    if (state is _Selecting) {
      final worldBounds = Rect.fromPoints(state.start, state.end);
      canvas.drawRect(
        worldBounds,
        Paint()
          ..color = SquiggleColors.selectionFill
          ..style = PaintingStyle.fill,
      );
      paintDashedRect(canvas, worldBounds);
    }
  }

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    switch (_state) {
      case _DraggingPolylinePoint():
        return EditorCursor.grabbing;
      case _Moving():
        return EditorCursor.grabbing;
      case _Resizing(:final handle):
        return _cursorForResizeHandle(handle);
      case _Idle():
      case _Selecting():
        break;
    }

    final document = context.document;
    final selectedPolyline = _selectedPolyline(document, context.selection);
    if (selectedPolyline != null &&
        _hitTestPolylineVertex(
              worldPoint: worldPosition,
              feature: selectedPolyline,
              camera: camera,
            ) !=
            null) {
      return EditorCursor.grab;
    }

    if (context.selection.selectedFeatures.length == 1) {
      final selected = document.featureById(
        context.selection.selectedFeatures.single,
      )!;
      final bounds = selected.bounds();
      final handle = _hitTestResizeHandle(
        worldPoint: worldPosition,
        featureBounds: bounds,
        camera: camera,
      );
      if (handle != null) {
        return _cursorForResizeHandle(handle);
      }
      if (selectionBoxWorldBounds(bounds).contains(worldPosition)) {
        return EditorCursor.grab;
      }
    }

    if (document.featureAtPoint(worldPosition) != null) {
      return EditorCursor.grab;
    }
    return EditorCursor.basic;
  }

  @override
  void deactivate(EditorContext context) {
    context.selection.clearSelection();
    _state = const _Idle();
    _lastTapFeatureId = null;
    _lastTapTime = null;
  }

  @override
  void onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final document = context.document;
    final selection = context.selection;

    if (_tryBeginPolylinePoint(document, worldPosition, selection, camera)) {
      return;
    }

    if (_tryBeginResize(document, worldPosition, selection, camera)) {
      return;
    }

    final feature = document.featureAtPoint(worldPosition);

    if (feature != null) {
      final didSelect = !selection.isFeatureSelected(feature.id);
      if (!isShiftPressed && !selection.isFeatureSelected(feature.id)) {
        selection.clearSelection();
      }
      selection.selectFeature(feature.id);

      final initialOrigins = _selectedFeatureOrigins(document, selection);
      _state = _Moving(
        initialOrigins: initialOrigins,
        moveOffset: worldPosition - feature.origin,
        pointerDownWorld: worldPosition,
        isFirstTimeSelect: didSelect,
        didMove: false,
        hasDuplicated: false,
        draggedFeatureId: feature.id,
        originsAtDragStart: _captureOrigins(
          document,
          selection.selectedFeatures,
        ),
      );
    } else {
      _state = _Selecting(start: worldPosition, end: worldPosition);
      if (!isShiftPressed) {
        selection.clearSelection();
      }
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
    final document = context.document;
    final selection = context.selection;
    switch (_state) {
      case _Idle():
        return;
      case _Selecting(:final start):
        _state = _Selecting(start: start, end: worldPosition);
        _updateMarqueeSelection(document, selection, isShiftPressed);
      case _DraggingPolylinePoint(
        :final featureId,
        :final pointIndex,
        :final dragOffset,
        :final initialOrigin,
        :final initialLocalPoints,
      ):
        final feature = document.featureById(featureId)!;
        final kind = feature.kind as FeatureKindPolyline;
        final points = worldPoints(feature.origin, kind.localPoints);
        var target = worldPosition - dragOffset;
        if (isShiftPressed) {
          final origin = pointIndex > 0
              ? points[pointIndex - 1]
              : points.length > 1
              ? points[1]
              : target;
          target = snapPointTo45DegreeAngle(origin, target);
        }
        _state = _DraggingPolylinePoint(
          featureId: featureId,
          pointIndex: pointIndex,
          dragOffset: dragOffset,
          initialOrigin: initialOrigin,
          initialLocalPoints: initialLocalPoints,
          didMove: true,
        );
        _movePolylinePoint(document, featureId, pointIndex, target);
      case _Moving(
        :final initialOrigins,
        :final moveOffset,
        :final pointerDownWorld,
        :final isFirstTimeSelect,
        :final didMove,
        :final hasDuplicated,
        :final draggedFeatureId,
        :final originsAtDragStart,
      ):
        var effectiveMoveOffset = moveOffset;
        var effectiveHasDuplicated = hasDuplicated;
        if (isAltPressed && !hasDuplicated) {
          effectiveMoveOffset = _tryAltDuplicate(
            context,
            worldPosition,
            draggedFeatureId,
            originsAtDragStart,
            moveOffset,
            didMove,
          );
          effectiveHasDuplicated = true;
        }
        _state = _Moving(
          initialOrigins: effectiveHasDuplicated
              ? _selectedFeatureOrigins(document, selection)
              : initialOrigins,
          moveOffset: effectiveMoveOffset,
          pointerDownWorld: pointerDownWorld,
          isFirstTimeSelect: isFirstTimeSelect,
          didMove: true,
          hasDuplicated: effectiveHasDuplicated,
          draggedFeatureId: draggedFeatureId,
          originsAtDragStart: originsAtDragStart,
        );
        final moveTarget = isShiftPressed
            ? constrainMoveToAxis(pointerDownWorld, worldPosition)
            : worldPosition;
        _moveSelectedFeatures(
          document,
          selection,
          moveTarget,
          effectiveMoveOffset,
        );
      case _Resizing(
        :final featureId,
        :final handle,
        :final anchor,
        :final initialBounds,
        :final resizeOffset,
      ):
        _state = _Resizing(
          featureId: featureId,
          handle: handle,
          anchor: anchor,
          initialBounds: initialBounds,
          resizeOffset: resizeOffset,
          didResize: true,
        );
        _resizeFeature(
          document,
          featureId,
          handle,
          anchor,
          initialBounds,
          worldPosition,
          resizeOffset,
          isAltPressed,
          isShiftPressed,
        );
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
    final document = context.document;
    final selection = context.selection;
    switch (_state) {
      case _DraggingPolylinePoint(
        :final featureId,
        :final pointIndex,
        :final initialOrigin,
        :final initialLocalPoints,
        :final didMove,
      ):
        if (didMove) {
          _commitPolylinePointMove(
            context,
            featureId,
            pointIndex,
            initialOrigin,
            initialLocalPoints,
          );
        }
        _state = const _Idle();
        return;
      case _Moving(
        :final initialOrigins,
        :final isFirstTimeSelect,
        :final didMove,
      ):
        if (didMove) {
          _commitMove(context, initialOrigins);
        }
        final hovered = document.featureAtPoint(worldPosition);
        if (hovered != null && !didMove) {
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
                  canvasLocalBounds: camera.worldToScreenBounds(
                    hovered.bounds(),
                  ),
                ),
              );
              _state = const _Idle();
              _lastTapFeatureId = null;
              _lastTapTime = null;
              return;
            }
          }
          _lastTapFeatureId = hovered.id;
          _lastTapTime = now;

          if (isShiftPressed) {
            if (!isFirstTimeSelect) {
              selection.deselectFeature(hovered.id);
            }
          } else {
            selection.clearSelection();
            selection.selectFeature(hovered.id);
          }
        }
      case _Resizing(:final featureId, :final initialBounds, :final didResize):
        if (didResize) {
          _commitResize(context, featureId, initialBounds);
        }
      case _Idle():
      case _Selecting():
        break;
    }
    _state = const _Idle();
  }

  Feature? _selectedPolyline(Document document, SelectionModel selection) {
    if (selection.selectedFeatures.length != 1) return null;

    final feature = document.featureById(selection.selectedFeatures.single);
    return feature?.kind is FeatureKindPolyline ? feature : null;
  }

  bool _tryBeginPolylinePoint(
    Document document,
    Offset worldPosition,
    SelectionModel selection,
    Camera camera,
  ) {
    final feature = _selectedPolyline(document, selection);
    if (feature == null) return false;

    final pointIndex = _hitTestPolylineVertex(
      worldPoint: worldPosition,
      feature: feature,
      camera: camera,
    );
    if (pointIndex == null) return false;

    final kind = feature.kind as FeatureKindPolyline;
    final points = worldPoints(feature.origin, kind.localPoints);
    _state = _DraggingPolylinePoint(
      featureId: feature.id,
      pointIndex: pointIndex,
      dragOffset: worldPosition - points[pointIndex],
      initialOrigin: feature.origin,
      initialLocalPoints: List.of(kind.localPoints),
      didMove: false,
    );
    return true;
  }

  int? _hitTestPolylineVertex({
    required Offset worldPoint,
    required Feature feature,
    required Camera camera,
  }) {
    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) return null;

    final screenPoint = camera.worldToScreen(worldPoint);
    final points = worldPoints(feature.origin, kind.localPoints);
    for (var i = 0; i < points.length; i++) {
      final screenCenter = camera.worldToScreen(points[i]);
      final hitRect = Rect.fromCenter(
        center: screenCenter,
        width: kSelectionHandleHitSize,
        height: kSelectionHandleHitSize,
      );
      if (hitRect.contains(screenPoint)) {
        return i;
      }
    }
    return null;
  }

  bool _tryBeginResize(
    Document document,
    Offset worldPosition,
    SelectionModel selection,
    Camera camera,
  ) {
    if (selection.selectedFeatures.length != 1) {
      return false;
    }

    final selectedId = selection.selectedFeatures.single;
    final selected = document.featureById(selectedId)!;

    final handle = _hitTestResizeHandle(
      worldPoint: worldPosition,
      featureBounds: selected.bounds(),
      camera: camera,
    );
    if (handle == null) {
      return false;
    }

    final bounds = selected.bounds();
    final reference = _referencePointForResizeHandle(handle, bounds);
    _state = _Resizing(
      featureId: selectedId,
      handle: handle,
      anchor: _anchorForResizeHandle(handle, bounds),
      initialBounds: bounds,
      resizeOffset: worldPosition - reference,
      didResize: false,
    );
    return true;
  }

  void _paintSelectionBox(Canvas canvas, Camera camera, Rect worldBounds) {
    canvas.save();
    canvas.translate(camera.location.dx, camera.location.dy);
    canvas.scale(camera.zoom, camera.zoom);

    final screenBounds = camera.worldToScreenBounds(worldBounds);
    final inflatedBounds = screenBounds.inflate(
      kSelectionBoxPadding / camera.zoom,
    );
    final half = kSelectionHandlePaintSize / 2;

    canvas.drawRect(
      inflatedBounds,
      Paint()
        ..color = SquiggleColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final center in [
      inflatedBounds.topLeft - Offset(half, half),
      inflatedBounds.topRight + Offset(half, -half),
      inflatedBounds.bottomLeft + Offset(-half, half),
      inflatedBounds.bottomRight + Offset(half, half),
    ]) {
      _paintSquareHandleAtScreenCenter(canvas, center);
    }
    canvas.restore();
  }

  void _paintHandle(Canvas canvas, Camera camera, Offset worldPoint) {
    canvas.save();
    canvas.translate(camera.location.dx, camera.location.dy);
    canvas.scale(camera.zoom, camera.zoom);
    _paintCircleHandleAtScreenCenter(canvas, camera.worldToScreen(worldPoint));
    canvas.restore();
  }

  void _paintSquareHandleAtScreenCenter(Canvas canvas, Offset center) {
    final handleRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: kSelectionHandlePaintSize,
        height: kSelectionHandlePaintSize,
      ),
      const Radius.circular(2.0),
    );
    canvas.drawRRect(
      handleRRect,
      Paint()
        ..color = SquiggleColors.base
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      handleRRect,
      Paint()
        ..color = SquiggleColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _paintCircleHandleAtScreenCenter(Canvas canvas, Offset center) {
    final radius = kSelectionHandlePaintSize / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = SquiggleColors.base
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = SquiggleColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
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

  SelectionResizeHandle? _hitTestResizeHandle({
    required Offset worldPoint,
    required Rect featureBounds,
    required Camera camera,
  }) {
    final screenPoint = camera.worldToScreen(worldPoint);
    final screenBounds = camera.worldToScreenBounds(featureBounds);
    final inflated = screenBounds.inflate(kSelectionBoxPadding / camera.zoom);
    final half = kSelectionHandleHitSize / 2;

    final handleCenters = <(SelectionResizeHandle, Offset)>[
      (SelectionResizeHandle.topLeft, inflated.topLeft - Offset(half, half)),
      (SelectionResizeHandle.topRight, inflated.topRight + Offset(half, -half)),
      (
        SelectionResizeHandle.bottomLeft,
        inflated.bottomLeft + Offset(-half, half),
      ),
      (
        SelectionResizeHandle.bottomRight,
        inflated.bottomRight + Offset(half, half),
      ),
    ];

    for (final (handle, center) in handleCenters) {
      final hitRect = Rect.fromCenter(
        center: center,
        width: kSelectionHandleHitSize,
        height: kSelectionHandleHitSize,
      );
      if (hitRect.contains(screenPoint)) {
        return handle;
      }
    }

    if (inflated.width <= kSelectionHandleHitSize ||
        inflated.height <= kSelectionHandleHitSize) {
      return null;
    }

    final edgeStrips = <(SelectionResizeHandle, Rect)>[
      (
        SelectionResizeHandle.top,
        Rect.fromLTWH(
          inflated.left + half,
          inflated.top - half,
          inflated.width - kSelectionHandleHitSize,
          kSelectionHandleHitSize,
        ),
      ),
      (
        SelectionResizeHandle.bottom,
        Rect.fromLTWH(
          inflated.left + half,
          inflated.bottom - half,
          inflated.width - kSelectionHandleHitSize,
          kSelectionHandleHitSize,
        ),
      ),
      (
        SelectionResizeHandle.left,
        Rect.fromLTWH(
          inflated.left - half,
          inflated.top + half,
          kSelectionHandleHitSize,
          inflated.height - kSelectionHandleHitSize,
        ),
      ),
      (
        SelectionResizeHandle.right,
        Rect.fromLTWH(
          inflated.right - half,
          inflated.top + half,
          kSelectionHandleHitSize,
          inflated.height - kSelectionHandleHitSize,
        ),
      ),
    ];

    for (final (handle, strip) in edgeStrips) {
      if (strip.contains(screenPoint)) {
        return handle;
      }
    }
    return null;
  }

  Offset _anchorForResizeHandle(SelectionResizeHandle handle, Rect bounds) {
    return switch (handle) {
      SelectionResizeHandle.topLeft => bounds.bottomRight,
      SelectionResizeHandle.top => bounds.bottomLeft,
      SelectionResizeHandle.topRight => bounds.bottomLeft,
      SelectionResizeHandle.right => bounds.topLeft,
      SelectionResizeHandle.bottomRight => bounds.topLeft,
      SelectionResizeHandle.bottom => bounds.topLeft,
      SelectionResizeHandle.bottomLeft => bounds.topRight,
      SelectionResizeHandle.left => bounds.topRight,
    };
  }

  Offset _referencePointForResizeHandle(
    SelectionResizeHandle handle,
    Rect bounds,
  ) {
    return switch (handle) {
      SelectionResizeHandle.topLeft => bounds.topLeft,
      SelectionResizeHandle.top => bounds.topLeft,
      SelectionResizeHandle.topRight => bounds.topRight,
      SelectionResizeHandle.right => bounds.bottomRight,
      SelectionResizeHandle.bottomRight => bounds.bottomRight,
      SelectionResizeHandle.bottom => bounds.bottomRight,
      SelectionResizeHandle.bottomLeft => bounds.bottomLeft,
      SelectionResizeHandle.left => bounds.topLeft,
    };
  }

  void _updateMarqueeSelection(
    Document document,
    SelectionModel selection,
    bool isShiftPressed,
  ) {
    final state = _state;
    if (state is! _Selecting) return;

    final bounds = Rect.fromPoints(state.start, state.end);
    final hits = document.nodes
        .where((f) => f.intersectsRect(bounds))
        .map((f) => f.id)
        .toList();

    if (isShiftPressed) {
      for (final id in hits) {
        selection.selectFeature(id);
      }
    } else {
      selection.setSelection(hits);
    }
  }

  Map<FeatureId, Offset> _captureOrigins(
    Document document,
    List<FeatureId> ids,
  ) {
    return {
      for (final id in ids)
        if (document.featureById(id) case final feature?) id: feature.origin,
    };
  }

  /// Duplicates the dragged selection for alt-drag, leaving originals at drag
  /// start. Returns the [moveOffset] for the clone under the cursor.
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
    var changed = false;
    for (final entry in targets.entries) {
      final feature = document.featureById(entry.key);
      if (feature != null && feature.origin != entry.value) {
        feature.moveTo(entry.value);
        changed = true;
      }
    }
    if (changed) document.notifyChanged();
  }

  Map<FeatureId, Offset> _selectedFeatureOrigins(
    Document document,
    SelectionModel selection,
  ) {
    return {
      for (final id in selection.selectedFeatures)
        if (document.featureById(id) case final feature?) id: feature.origin,
    };
  }

  void _commitMove(
    EditorContext context,
    Map<FeatureId, Offset> initialOrigins,
  ) {
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

  void _resizeFeature(
    Document document,
    FeatureId featureId,
    SelectionResizeHandle handle,
    Offset anchor,
    Rect initialBounds,
    Offset pointerWorld,
    Offset resizeOffset,
    bool symmetric,
    bool lockAspectRatio,
  ) {
    final dragged = pointerWorld - resizeOffset;
    final aspectRatio = initialBounds.width / initialBounds.height;
    final newBounds = symmetric
        ? _symmetricBoundsForResize(
            handle,
            initialBounds,
            dragged,
            lockAspectRatio: lockAspectRatio,
            aspectRatio: aspectRatio,
          )
        : _asymmetricBoundsForResize(
            handle,
            anchor,
            initialBounds,
            dragged,
            lockAspectRatio: lockAspectRatio,
            aspectRatio: aspectRatio,
          );

    final feature = document.featureById(featureId);
    if (feature == null) return;
    feature.setBounds(newBounds);
    document.notifyChanged();
  }

  void _commitResize(
    EditorContext context,
    FeatureId featureId,
    Rect initialBounds,
  ) {
    final feature = context.document.featureById(featureId);
    if (feature == null) return;

    final finalBounds = feature.bounds();
    if (finalBounds == initialBounds) return;

    context.record(
      ResizeFeatureCommand(
        id: featureId,
        initialBounds: initialBounds,
        finalBounds: finalBounds,
      ),
    );
  }

  void _movePolylinePoint(
    Document document,
    FeatureId featureId,
    int pointIndex,
    Offset worldPosition,
  ) {
    final feature = document.featureById(featureId);
    if (feature == null) return;

    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) return;

    final points = worldPoints(feature.origin, kind.localPoints);
    if (pointIndex < 0 || pointIndex >= points.length) return;

    kind.setPoint(feature, pointIndex, worldPosition);
    document.notifyChanged();
  }

  void _commitPolylinePointMove(
    EditorContext context,
    FeatureId featureId,
    int pointIndex,
    Offset initialOrigin,
    List<Offset> initialLocalPoints,
  ) {
    final document = context.document;
    final feature = document.featureById(featureId);
    if (feature == null) return;

    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) return;

    final finalPoints = worldPoints(feature.origin, kind.localPoints);
    if (pointIndex < 0 || pointIndex >= finalPoints.length) return;

    final initialWorldPoints = worldPoints(initialOrigin, initialLocalPoints);
    if (pointIndex >= initialWorldPoints.length ||
        finalPoints[pointIndex] == initialWorldPoints[pointIndex]) {
      return;
    }

    context.record(
      MovePolylinePointCommand(
        id: featureId,
        pointIndex: pointIndex,
        initialOrigin: initialOrigin,
        initialLocalPoints: initialLocalPoints,
        finalWorldPosition: finalPoints[pointIndex],
      ),
    );
  }

  Rect _asymmetricBoundsForResize(
    SelectionResizeHandle handle,
    Offset anchor,
    Rect bounds,
    Offset dragged, {
    required bool lockAspectRatio,
    required double aspectRatio,
  }) {
    if (lockAspectRatio) {
      return switch (handle) {
        SelectionResizeHandle.topLeft ||
        SelectionResizeHandle.topRight ||
        SelectionResizeHandle.bottomLeft ||
        SelectionResizeHandle.bottomRight => rectFromAnchorWithAspectRatio(
          anchor,
          dragged,
          aspectRatio,
        ),
        SelectionResizeHandle.top => edgeResizeWithAspectRatio(
          bounds,
          dragged,
          resizeTop: true,
          resizeBottom: false,
          resizeLeft: false,
          resizeRight: false,
          aspectRatio: aspectRatio,
        ),
        SelectionResizeHandle.bottom => edgeResizeWithAspectRatio(
          bounds,
          dragged,
          resizeTop: false,
          resizeBottom: true,
          resizeLeft: false,
          resizeRight: false,
          aspectRatio: aspectRatio,
        ),
        SelectionResizeHandle.left => edgeResizeWithAspectRatio(
          bounds,
          dragged,
          resizeTop: false,
          resizeBottom: false,
          resizeLeft: true,
          resizeRight: false,
          aspectRatio: aspectRatio,
        ),
        SelectionResizeHandle.right => edgeResizeWithAspectRatio(
          bounds,
          dragged,
          resizeTop: false,
          resizeBottom: false,
          resizeLeft: false,
          resizeRight: true,
          aspectRatio: aspectRatio,
        ),
      };
    }

    return switch (handle) {
      SelectionResizeHandle.topLeft ||
      SelectionResizeHandle.topRight ||
      SelectionResizeHandle.bottomLeft ||
      SelectionResizeHandle.bottomRight => Rect.fromPoints(anchor, dragged),
      SelectionResizeHandle.top => Rect.fromLTRB(
        bounds.left,
        dragged.dy,
        bounds.right,
        bounds.bottom,
      ),
      SelectionResizeHandle.bottom => Rect.fromLTRB(
        bounds.left,
        bounds.top,
        bounds.right,
        dragged.dy,
      ),
      SelectionResizeHandle.left => Rect.fromLTRB(
        dragged.dx,
        bounds.top,
        bounds.right,
        bounds.bottom,
      ),
      SelectionResizeHandle.right => Rect.fromLTRB(
        bounds.left,
        bounds.top,
        dragged.dx,
        bounds.bottom,
      ),
    };
  }

  Rect _symmetricBoundsForResize(
    SelectionResizeHandle handle,
    Rect initialBounds,
    Offset dragged, {
    required bool lockAspectRatio,
    required double aspectRatio,
  }) {
    final center = initialBounds.center;
    if (lockAspectRatio) {
      return switch (handle) {
        SelectionResizeHandle.topLeft ||
        SelectionResizeHandle.topRight ||
        SelectionResizeHandle.bottomLeft ||
        SelectionResizeHandle.bottomRight => symmetricRectWithAspectRatio(
          center,
          dragged,
          aspectRatio,
          resizeHorizontal: true,
          resizeVertical: true,
        ),
        SelectionResizeHandle.top ||
        SelectionResizeHandle.bottom => symmetricRectWithAspectRatio(
          center,
          dragged,
          aspectRatio,
          resizeHorizontal: false,
          resizeVertical: true,
        ),
        SelectionResizeHandle.left ||
        SelectionResizeHandle.right => symmetricRectWithAspectRatio(
          center,
          dragged,
          aspectRatio,
          resizeHorizontal: true,
          resizeVertical: false,
        ),
      };
    }

    return switch (handle) {
      SelectionResizeHandle.topLeft ||
      SelectionResizeHandle.topRight ||
      SelectionResizeHandle.bottomLeft ||
      SelectionResizeHandle.bottomRight => Rect.fromCenter(
        center: center,
        width: (dragged.dx - center.dx).abs() * 2,
        height: (dragged.dy - center.dy).abs() * 2,
      ),
      SelectionResizeHandle.top ||
      SelectionResizeHandle.bottom => Rect.fromCenter(
        center: center,
        width: initialBounds.width,
        height: (dragged.dy - center.dy).abs() * 2,
      ),
      SelectionResizeHandle.left ||
      SelectionResizeHandle.right => Rect.fromCenter(
        center: center,
        width: (dragged.dx - center.dx).abs() * 2,
        height: initialBounds.height,
      ),
    };
  }

  @override
  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    final isCtrlG =
        event.logicalKey == LogicalKeyboardKey.keyG &&
        HardwareKeyboard.instance.isControlPressed;

    if (context.selection.isEmpty) return false;
    if (!isCtrlG) return false;

    // print(
    //   'Ctrl+G detected during selection with ${context.selection.selectedFeatures.length} features!',
    // );
    return true;
  }
}

sealed class _SelectState {
  const _SelectState();
}

final class _Idle extends _SelectState {
  const _Idle();
}

final class _Selecting extends _SelectState {
  const _Selecting({required this.start, required this.end});

  final Offset start;
  final Offset end;
}

final class _DraggingPolylinePoint extends _SelectState {
  const _DraggingPolylinePoint({
    required this.featureId,
    required this.pointIndex,
    required this.dragOffset,
    required this.initialOrigin,
    required this.initialLocalPoints,
    required this.didMove,
  });

  final FeatureId featureId;
  final int pointIndex;
  final Offset dragOffset;
  final Offset initialOrigin;
  final List<Offset> initialLocalPoints;
  final bool didMove;
}

final class _Moving extends _SelectState {
  const _Moving({
    required this.initialOrigins,
    required this.moveOffset,
    required this.pointerDownWorld,
    required this.isFirstTimeSelect,
    required this.didMove,
    required this.hasDuplicated,
    required this.draggedFeatureId,
    required this.originsAtDragStart,
  });

  final Map<FeatureId, Offset> initialOrigins;
  final Offset moveOffset;
  final Offset pointerDownWorld;
  final bool isFirstTimeSelect;
  final bool didMove;
  final bool hasDuplicated;
  final FeatureId draggedFeatureId;
  final Map<FeatureId, Offset> originsAtDragStart;
}

final class _Resizing extends _SelectState {
  const _Resizing({
    required this.featureId,
    required this.handle,
    required this.anchor,
    required this.initialBounds,
    required this.resizeOffset,
    required this.didResize,
  });

  final FeatureId featureId;
  final SelectionResizeHandle handle;
  final Offset anchor;
  final Rect initialBounds;
  final Offset resizeOffset;
  final bool didResize;
}
