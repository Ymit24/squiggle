import 'dart:ui';

import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature_id.dart';

import 'select_interaction.dart';
import 'select_resize_geometry.dart';

/// Resizes a single selected feature from one of its resize handles.
class ResizeInteraction extends SelectInteraction {
  ResizeInteraction({
    required this.featureId,
    required this.handle,
    required this.anchor,
    required this.initialBounds,
    required this.resizeOffset,
    this.resumeEditing,
  });

  final FeatureId featureId;
  final SelectionResizeHandle handle;
  final Offset anchor;
  final Rect initialBounds;
  final Offset resizeOffset;
  final FeatureId? resumeEditing;

  bool _didResize = false;

  bool get didResize => _didResize;

  @override
  void update(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final dragged = worldPosition - resizeOffset;
    final aspectRatio = initialBounds.width / initialBounds.height;
    final newBounds = isAltPressed
        ? symmetricBoundsForResize(
            handle,
            initialBounds,
            dragged,
            lockAspectRatio: isShiftPressed,
            aspectRatio: aspectRatio,
          )
        : asymmetricBoundsForResize(
            handle,
            anchor,
            initialBounds,
            dragged,
            lockAspectRatio: isShiftPressed,
            aspectRatio: aspectRatio,
          );
    _didResize = true;
    context.document.setFeatureBounds(featureId, newBounds);
  }

  @override
  void commit(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (!_didResize) return;

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
}