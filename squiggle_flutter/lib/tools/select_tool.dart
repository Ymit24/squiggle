import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
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

  FeatureId? get _editingFeatureId => switch (_state) {
    _Editing(:final featureId) => featureId,
    _EditingPoint(:final featureId) => featureId,
    _ => null,
  };

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    DocumentRepository documentRepository,
    SelectionRepository selection,
  ) {
    final document = documentRepository.document;

    for (final featureId in selection.selectedFeatures) {
      final feature = document.featureById(featureId);
      if (feature != null) {
        _paintSelectionBox(canvas, camera, feature.bounds());
      }
    }

    final editingFeatureId = _editingFeatureId;
    if (editingFeatureId != null) {
      final feature = document.featureById(editingFeatureId);
      if (feature != null && feature.kind is FeatureKindPolyline) {
        final kind = feature.kind as FeatureKindPolyline;
        for (final point in worldPoints(feature.origin, kind.localPoints)) {
          _paintHandle(canvas, camera, point);
        }
      }
    }

    final state = _state;
    if (state is _Selecting) {
      final worldBounds = Rect.fromPoints(state.start, state.end);
      canvas.drawRect(
        worldBounds,
        Paint()
          ..color = const Color(0xFF89B4FA).withValues(alpha: 0.06)
          ..style = PaintingStyle.fill,
      );
      paintDashedRect(canvas, worldBounds);
    }
  }

  @override
  EditorCursor resolveCursor(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    Camera camera,
  ) {
    switch (_state) {
      case _EditingPoint():
        return EditorCursor.grabbing;
      case _Moving():
        return EditorCursor.grabbing;
      case _Resizing(:final handle):
        return _cursorForResizeHandle(handle);
      case _Idle():
      case _Selecting():
      case _Editing():
        break;
    }

    final document = documentRepository.document;
    final editingFeatureId = _editingFeatureId;
    if (editingFeatureId != null) {
      final feature = document.featureById(editingFeatureId);
      if (feature != null &&
          _hitTestPolylineVertex(
                worldPoint: worldPosition,
                feature: feature,
                camera: camera,
              ) !=
              null) {
        return EditorCursor.grab;
      }
    }

    if (selection.selectedFeatures.length == 1) {
      final selected = document.featureById(selection.selectedFeatures.single)!;
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
  void deactivate(SelectionRepository selection) {
    selection.clearSelection();
    _state = const _Idle();
    _lastTapFeatureId = null;
    _lastTapTime = null;
  }

  @override
  bool onKeyEvent(
    DocumentRepository documentRepository,
    KeyDownEvent event,
  ) {
    if (_state is! _Editing) {
      return false;
    }
    if (event.logicalKey != LogicalKeyboardKey.enter &&
        event.logicalKey != LogicalKeyboardKey.escape) {
      return false;
    }
    _state = const _Idle();
    return true;
  }

  @override
  void onPointerDown(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    Camera camera,
  ) {
    final document = documentRepository.document;
    final editingFeatureId = _editingFeatureId;

    if (editingFeatureId != null &&
        _tryBeginEditPoint(
          document,
          worldPosition,
          editingFeatureId,
          camera,
        )) {
      return;
    }

    if (_tryBeginResize(
      document,
      worldPosition,
      selection,
      camera,
      resumeEditing: editingFeatureId,
    )) {
      return;
    }

    final feature = document.featureAtPoint(worldPosition);

    if (feature != null) {
      if (editingFeatureId != null && feature.id != editingFeatureId) {
        _exitEditing();
      }

      final didSelect = !selection.isFeatureSelected(feature.id);
      if (!isShiftPressed && !selection.isFeatureSelected(feature.id)) {
        selection.clearSelection();
      }
      selection.selectFeature(feature.id);

      final resumeEditing =
          editingFeatureId != null && feature.id == editingFeatureId
          ? editingFeatureId
          : null;
      _state = _Moving(
        moveOffset: worldPosition - feature.origin,
        isFirstTimeSelect: didSelect,
        didMove: false,
        resumeEditing: resumeEditing,
      );
    } else {
      if (editingFeatureId != null) {
        _exitEditing();
      }
      _state = _Selecting(start: worldPosition, end: worldPosition);
      if (!isShiftPressed) {
        selection.clearSelection();
      }
    }
  }

  @override
  void onPointerMove(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    Camera camera,
  ) {
    final document = documentRepository.document;
    switch (_state) {
      case _Idle():
      case _Editing():
        return;
      case _Selecting(:final start):
        _state = _Selecting(start: start, end: worldPosition);
        _updateMarqueeSelection(document, selection, isShiftPressed);
      case _EditingPoint(
        :final featureId,
        :final pointIndex,
        :final dragOffset,
      ):
        _state = _EditingPoint(
          featureId: featureId,
          pointIndex: pointIndex,
          dragOffset: dragOffset,
          didMove: true,
        );
        documentRepository.executeCommand(
          MovePolylinePointCommand(
            featureId,
            pointIndex,
            worldPosition - dragOffset,
          ),
        );
      case _Moving(:final moveOffset, :final isFirstTimeSelect, :final resumeEditing):
        _state = _Moving(
          moveOffset: moveOffset,
          isFirstTimeSelect: isFirstTimeSelect,
          didMove: true,
          resumeEditing: resumeEditing,
        );
        _moveSelectedFeatures(
          documentRepository,
          selection,
          worldPosition,
          moveOffset,
        );
      case _Resizing(
        :final featureId,
        :final handle,
        :final anchor,
        :final resizeOffset,
        :final resumeEditing,
      ):
        _state = _Resizing(
          featureId: featureId,
          handle: handle,
          anchor: anchor,
          resizeOffset: resizeOffset,
          didResize: true,
          resumeEditing: resumeEditing,
        );
        _resizeFeature(
          documentRepository,
          featureId,
          handle,
          anchor,
          worldPosition,
          resizeOffset,
        );
    }
  }

  @override
  void onPointerUp(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    Camera camera,
  ) {
    final document = documentRepository.document;
    switch (_state) {
      case _EditingPoint(:final featureId):
        _state = _Editing(featureId: featureId);
        return;
      case _Moving(:final isFirstTimeSelect, :final didMove, :final resumeEditing):
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
            _state = _Editing(featureId: hovered.id);
            _lastTapFeatureId = null;
            _lastTapTime = null;
            return;
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
        if (resumeEditing != null) {
          _state = _Editing(featureId: resumeEditing);
          return;
        }
      case _Resizing(:final resumeEditing):
        if (resumeEditing != null) {
          _state = _Editing(featureId: resumeEditing);
          return;
        }
      case _Idle():
      case _Selecting():
      case _Editing():
        break;
    }
    _state = const _Idle();
  }

  void _exitEditing() {
    if (_state is _Editing || _state is _EditingPoint) {
      _state = const _Idle();
    }
  }

  bool _tryBeginEditPoint(
    Document document,
    Offset worldPosition,
    FeatureId editingFeatureId,
    Camera camera,
  ) {
    final feature = document.featureById(editingFeatureId);
    if (feature == null) return false;

    final pointIndex = _hitTestPolylineVertex(
      worldPoint: worldPosition,
      feature: feature,
      camera: camera,
    );
    if (pointIndex == null) return false;

    final kind = feature.kind as FeatureKindPolyline;
    final points = worldPoints(feature.origin, kind.localPoints);
    _state = _EditingPoint(
      featureId: editingFeatureId,
      pointIndex: pointIndex,
      dragOffset: worldPosition - points[pointIndex],
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
    SelectionRepository selection,
    Camera camera, {
    FeatureId? resumeEditing,
  }) {
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
      resizeOffset: worldPosition - reference,
      didResize: false,
      resumeEditing: resumeEditing,
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
    SelectionRepository selection,
    bool isShiftPressed,
  ) {
    final state = _state;
    if (state is! _Selecting) return;

    final bounds = Rect.fromPoints(state.start, state.end);
    final hits = document.features
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

  void _moveSelectedFeatures(
    DocumentRepository documentRepository,
    SelectionRepository selection,
    Offset worldPosition,
    Offset moveOffset,
  ) {
    final document = documentRepository.document;
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

    for (final entry in offsets.entries) {
      documentRepository.executeCommand(
        MoveFeatureCommand(entry.key, worldPosition - moveOffset + entry.value),
      );
    }
  }

  void _resizeFeature(
    DocumentRepository documentRepository,
    FeatureId featureId,
    SelectionResizeHandle handle,
    Offset anchor,
    Offset pointerWorld,
    Offset resizeOffset,
  ) {
    final dragged = pointerWorld - resizeOffset;
    final bounds = documentRepository.document.featureById(featureId)!.bounds();
    final newBounds = switch (handle) {
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

    documentRepository.executeCommand(
      ResizeFeatureCommand(featureId, newBounds),
    );
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

final class _Editing extends _SelectState {
  const _Editing({required this.featureId});

  final FeatureId featureId;
}

final class _EditingPoint extends _SelectState {
  const _EditingPoint({
    required this.featureId,
    required this.pointIndex,
    required this.dragOffset,
    required this.didMove,
  });

  final FeatureId featureId;
  final int pointIndex;
  final Offset dragOffset;
  final bool didMove;
}

final class _Moving extends _SelectState {
  const _Moving({
    required this.moveOffset,
    required this.isFirstTimeSelect,
    required this.didMove,
    this.resumeEditing,
  });

  final Offset moveOffset;
  final bool isFirstTimeSelect;
  final bool didMove;
  final FeatureId? resumeEditing;
}

final class _Resizing extends _SelectState {
  const _Resizing({
    required this.featureId,
    required this.handle,
    required this.anchor,
    required this.resizeOffset,
    required this.didResize,
    this.resumeEditing,
  });

  final FeatureId featureId;
  final SelectionResizeHandle handle;
  final Offset anchor;
  final Offset resizeOffset;
  final bool didResize;
  final FeatureId? resumeEditing;
}
