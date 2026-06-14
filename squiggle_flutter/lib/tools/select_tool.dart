import 'dart:ui';

import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';
import 'package:squiggle_flutter/utils/painting.dart';

const kSelectionBoxPadding = 8.0;
const kSelectionHandleHitSize = 20.0;

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

  @override
  void paint(Canvas canvas) {
    final state = _state;
    if (state is! _Selecting) return;

    final worldBounds = Rect.fromPoints(state.start, state.end);
    canvas.drawRect(
      worldBounds,
      Paint()
        ..color = const Color(0xFF89B4FA).withValues(alpha: 0.06)
        ..style = PaintingStyle.fill,
    );
    paintDashedRect(canvas, worldBounds);
  }

  @override
  EditorCursor resolveCursor(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    Camera camera,
  ) {
    switch (_state) {
      case _Moving():
        return EditorCursor.grabbing;
      case _Resizing(:final handle):
        return _cursorForResizeHandle(handle);
      case _Idle():
      case _Selecting():
        break;
    }

    final document = documentRepository.document;
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

      _state = _Moving(
        moveOffset: worldPosition - feature.origin,
        isFirstTimeSelect: didSelect,
        didMove: false,
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
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    Camera camera,
  ) {
    final document = documentRepository.document;
    switch (_state) {
      case _Idle():
        return;
      case _Selecting(:final start):
        _state = _Selecting(start: start, end: worldPosition);
        _updateMarqueeSelection(document, selection, isShiftPressed);
      case _Moving(:final moveOffset, :final isFirstTimeSelect):
        _state = _Moving(
          moveOffset: moveOffset,
          isFirstTimeSelect: isFirstTimeSelect,
          didMove: true,
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
      ):
        _state = _Resizing(
          featureId: featureId,
          handle: handle,
          anchor: anchor,
          resizeOffset: resizeOffset,
          didResize: true,
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
      case _Moving(:final isFirstTimeSelect, :final didMove):
        final hovered = document.featureAtPoint(worldPosition);
        if (hovered != null && !didMove) {
          if (isShiftPressed) {
            if (!isFirstTimeSelect) {
              selection.deselectFeature(hovered.id);
            }
          } else {
            selection.clearSelection();
            selection.selectFeature(hovered.id);
          }
        }
      case _Idle():
      case _Selecting():
      case _Resizing():
        break;
    }
    _state = const _Idle();
  }

  bool _tryBeginResize(
    Document document,
    Offset worldPosition,
    SelectionRepository selection,
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
      resizeOffset: worldPosition - reference,
      didResize: false,
    );
    return true;
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

final class _Moving extends _SelectState {
  const _Moving({
    required this.moveOffset,
    required this.isFirstTimeSelect,
    required this.didMove,
  });

  final Offset moveOffset;
  final bool isFirstTimeSelect;
  final bool didMove;
}

final class _Resizing extends _SelectState {
  const _Resizing({
    required this.featureId,
    required this.handle,
    required this.anchor,
    required this.resizeOffset,
    required this.didResize,
  });

  final FeatureId featureId;
  final SelectionResizeHandle handle;
  final Offset anchor;
  final Offset resizeOffset;
  final bool didResize;
}
