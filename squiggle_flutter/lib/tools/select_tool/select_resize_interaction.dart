import 'dart:ui';

import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/tools/editor_interaction.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

/// Select-tool interaction for dragging a selected polyline vertex.
class SelectResizeInteraction extends EditorInteraction {
  FeatureId? _featureId;
  SelectionResizeHandle? _handle;
  Rect? _initialBounds;
  Offset? _anchor;
  Offset? _resizeOffset;
  bool _didResize = false;

  SelectionResizeHandle? get handle => _handle;

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (context.selection.selectedFeatures.length != 1) return false;
    final id = context.selection.selectedFeatures.single;
    final feature = context.document.featureById(id);
    if (feature == null) return false;

    final bounds = feature.bounds();
    final handle = _hitTestHandle(worldPosition, bounds, camera);
    if (handle == null) return false;

    _featureId = id;
    _handle = handle;
    _initialBounds = bounds;
    _anchor = _anchorFor(handle, bounds);
    _resizeOffset = worldPosition - _referenceFor(handle, bounds);
    _didResize = false;
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
    final id = _featureId;
    final handle = _handle;
    final bounds = _initialBounds;
    final anchor = _anchor;
    final offset = _resizeOffset;
    if (id == null ||
        handle == null ||
        bounds == null ||
        anchor == null ||
        offset == null) {
      return false;
    }

    final feature = context.document.featureById(id);
    if (feature == null) return false;

    final dragged = worldPosition - offset;
    final ratio = bounds.width / bounds.height;
    final nextBounds = isAltPressed
        ? _symmetricBounds(handle, bounds, dragged, isShiftPressed, ratio)
        : _asymmetricBounds(
            handle,
            anchor,
            bounds,
            dragged,
            isShiftPressed,
            ratio,
          );
    feature.resize(nextBounds);
    context.notifyViewportChanged();
    _didResize = true;
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
    final id = _featureId;
    final initialBounds = _initialBounds;
    if (_didResize && id != null && initialBounds != null) {
      final feature = context.document.featureById(id);
      if (feature != null && feature.bounds() != initialBounds) {
        context.record(
          ResizeFeatureCommand(
            id: id,
            initialBounds: initialBounds,
            finalBounds: feature.bounds(),
          ),
        );
      }
    }
    _clear();
    return true;
  }

  @override
  void deactivate(EditorContext context) => _clear();

  void _clear() {
    _featureId = null;
    _handle = null;
    _initialBounds = null;
    _anchor = null;
    _resizeOffset = null;
    _didResize = false;
  }

  SelectionResizeHandle? _hitTestHandle(
    Offset point,
    Rect bounds,
    Camera camera,
  ) {
    final screenPoint = camera.worldToScreen(point);
    final screenBounds = camera
        .worldToScreenBounds(bounds)
        .inflate(kSelectionBoxPadding / camera.zoom);
    final half = kSelectionHandleHitSize / 2;
    final handles = <(SelectionResizeHandle, Offset)>[
      (
        SelectionResizeHandle.topLeft,
        screenBounds.topLeft - Offset(half, half),
      ),
      (
        SelectionResizeHandle.topRight,
        screenBounds.topRight + Offset(half, -half),
      ),
      (
        SelectionResizeHandle.bottomLeft,
        screenBounds.bottomLeft + Offset(-half, half),
      ),
      (
        SelectionResizeHandle.bottomRight,
        screenBounds.bottomRight + Offset(half, half),
      ),
    ];
    for (final (handle, center) in handles) {
      if (Rect.fromCenter(
        center: center,
        width: kSelectionHandleHitSize,
        height: kSelectionHandleHitSize,
      ).contains(screenPoint)) {
        return handle;
      }
    }

    if (screenBounds.width <= kSelectionHandleHitSize ||
        screenBounds.height <= kSelectionHandleHitSize) {
      return null;
    }

    final edgeStrips = <(SelectionResizeHandle, Rect)>[
      (
        SelectionResizeHandle.top,
        Rect.fromLTWH(
          screenBounds.left + half,
          screenBounds.top - half,
          screenBounds.width - kSelectionHandleHitSize,
          kSelectionHandleHitSize,
        ),
      ),
      (
        SelectionResizeHandle.bottom,
        Rect.fromLTWH(
          screenBounds.left + half,
          screenBounds.bottom - half,
          screenBounds.width - kSelectionHandleHitSize,
          kSelectionHandleHitSize,
        ),
      ),
      (
        SelectionResizeHandle.left,
        Rect.fromLTWH(
          screenBounds.left - half,
          screenBounds.top + half,
          kSelectionHandleHitSize,
          screenBounds.height - kSelectionHandleHitSize,
        ),
      ),
      (
        SelectionResizeHandle.right,
        Rect.fromLTWH(
          screenBounds.right - half,
          screenBounds.top + half,
          kSelectionHandleHitSize,
          screenBounds.height - kSelectionHandleHitSize,
        ),
      ),
    ];
    for (final (handle, strip) in edgeStrips) {
      if (strip.contains(screenPoint)) return handle;
    }
    return null;
  }

  Offset _anchorFor(SelectionResizeHandle handle, Rect b) => switch (handle) {
    SelectionResizeHandle.topLeft || SelectionResizeHandle.top => b.bottomRight,
    SelectionResizeHandle.topRight => b.bottomLeft,
    SelectionResizeHandle.right ||
    SelectionResizeHandle.bottomRight ||
    SelectionResizeHandle.bottom => b.topLeft,
    SelectionResizeHandle.bottomLeft ||
    SelectionResizeHandle.left => b.topRight,
  };

  Offset _referenceFor(SelectionResizeHandle handle, Rect b) =>
      switch (handle) {
        SelectionResizeHandle.topLeft ||
        SelectionResizeHandle.top ||
        SelectionResizeHandle.left => b.topLeft,
        SelectionResizeHandle.topRight => b.topRight,
        SelectionResizeHandle.right ||
        SelectionResizeHandle.bottomRight ||
        SelectionResizeHandle.bottom => b.bottomRight,
        SelectionResizeHandle.bottomLeft => b.bottomLeft,
      };

  Rect _asymmetricBounds(
    SelectionResizeHandle handle,
    Offset anchor,
    Rect b,
    Offset dragged,
    bool lockAspect,
    double ratio,
  ) {
    if (!lockAspect) {
      return switch (handle) {
        SelectionResizeHandle.topLeft ||
        SelectionResizeHandle.topRight ||
        SelectionResizeHandle.bottomLeft ||
        SelectionResizeHandle.bottomRight => Rect.fromPoints(anchor, dragged),
        SelectionResizeHandle.top => Rect.fromLTRB(
          b.left,
          dragged.dy,
          b.right,
          b.bottom,
        ),
        SelectionResizeHandle.bottom => Rect.fromLTRB(
          b.left,
          b.top,
          b.right,
          dragged.dy,
        ),
        SelectionResizeHandle.left => Rect.fromLTRB(
          dragged.dx,
          b.top,
          b.right,
          b.bottom,
        ),
        SelectionResizeHandle.right => Rect.fromLTRB(
          b.left,
          b.top,
          dragged.dx,
          b.bottom,
        ),
      };
    }
    return switch (handle) {
      SelectionResizeHandle.topLeft ||
      SelectionResizeHandle.topRight ||
      SelectionResizeHandle.bottomLeft ||
      SelectionResizeHandle.bottomRight => rectFromAnchorWithAspectRatio(
        anchor,
        dragged,
        ratio,
      ),
      SelectionResizeHandle.top => edgeResizeWithAspectRatio(
        b,
        dragged,
        resizeTop: true,
        resizeBottom: false,
        resizeLeft: false,
        resizeRight: false,
        aspectRatio: ratio,
      ),
      SelectionResizeHandle.bottom => edgeResizeWithAspectRatio(
        b,
        dragged,
        resizeTop: false,
        resizeBottom: true,
        resizeLeft: false,
        resizeRight: false,
        aspectRatio: ratio,
      ),
      SelectionResizeHandle.left => edgeResizeWithAspectRatio(
        b,
        dragged,
        resizeTop: false,
        resizeBottom: false,
        resizeLeft: true,
        resizeRight: false,
        aspectRatio: ratio,
      ),
      SelectionResizeHandle.right => edgeResizeWithAspectRatio(
        b,
        dragged,
        resizeTop: false,
        resizeBottom: false,
        resizeLeft: false,
        resizeRight: true,
        aspectRatio: ratio,
      ),
    };
  }

  Rect _symmetricBounds(
    SelectionResizeHandle handle,
    Rect b,
    Offset dragged,
    bool lockAspect,
    double ratio,
  ) {
    final center = b.center;
    if (lockAspect) {
      final both =
          handle == SelectionResizeHandle.topLeft ||
          handle == SelectionResizeHandle.topRight ||
          handle == SelectionResizeHandle.bottomLeft ||
          handle == SelectionResizeHandle.bottomRight;
      return symmetricRectWithAspectRatio(
        center,
        dragged,
        ratio,
        resizeHorizontal:
            both ||
            handle == SelectionResizeHandle.left ||
            handle == SelectionResizeHandle.right,
        resizeVertical:
            both ||
            handle == SelectionResizeHandle.top ||
            handle == SelectionResizeHandle.bottom,
      );
    }
    final horizontal =
        handle == SelectionResizeHandle.left ||
        handle == SelectionResizeHandle.right ||
        handle == SelectionResizeHandle.topLeft ||
        handle == SelectionResizeHandle.topRight ||
        handle == SelectionResizeHandle.bottomLeft ||
        handle == SelectionResizeHandle.bottomRight;
    final vertical =
        handle == SelectionResizeHandle.top ||
        handle == SelectionResizeHandle.bottom ||
        handle == SelectionResizeHandle.topLeft ||
        handle == SelectionResizeHandle.topRight ||
        handle == SelectionResizeHandle.bottomLeft ||
        handle == SelectionResizeHandle.bottomRight;
    return Rect.fromCenter(
      center: center,
      width: horizontal ? (dragged.dx - center.dx).abs() * 2 : b.width,
      height: vertical ? (dragged.dy - center.dy).abs() * 2 : b.height,
    );
  }
}

/// Select-tool interaction for marquee selection.
