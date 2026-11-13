import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_binding.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/utils/painting.dart';

/// Paints the visual affordances used by selection tools.
///
/// The canvas is expected to already have the document's world transform
/// applied. Screen-sized values are converted to world units before painting
/// so handles remain a constant size at every zoom level.
abstract final class SelectionPainter {
  static const boxPadding = 8.0;
  static const handleSize = 12.0;

  /// Paints selection boxes and any handles associated with the selection.
  static void paintSelection(
    Canvas canvas,
    Camera camera,
    EditorContext context,
  ) {
    paintSelectedFeatureBoxes(canvas, camera, context);
    paintSelectedPolylineHandles(canvas, camera, context);
  }

  static void paintSelectedFeatureBoxes(
    Canvas canvas,
    Camera camera,
    EditorContext context,
  ) {
    final showResizeHandles = context.selection.selectedNodeIds.length == 1;
    for (final featureId in context.selection.selectedNodeIds) {
      // The inline text editor is the frame while a feature's text is edited.
      if (context.textEdit.isEditing(featureId)) continue;
      final node = context.document.requireNodeById(featureId);
      paintSelectionBox(
        canvas,
        camera,
        node.localBounds(),
        showResizeHandles: showResizeHandles,
      );
    }
  }

  static void paintSelectedPolylineHandles(
    Canvas canvas,
    Camera camera,
    EditorContext context,
  ) {
    if (context.selection.selectedNodeIds.length != 1) return;

    final selectedId = context.selection.selectedNodeIds.single;
    final node = context.document.requireNodeById(selectedId);
    if (node is! Feature || node.kind is! FeatureKindPolyline) return;

    final kind = node.kind as FeatureKindPolyline;
    final points = kind.resolvedPoints(node);
    // A binding whose target is gone is kept for undo but attaches nothing.
    bool isAttached(NodeBinding? binding) =>
        binding?.target(context.document) != null;
    for (final (index, point) in points.indexed) {
      final isBound =
          (index == 0 && isAttached(kind.startBinding)) ||
          (index == points.length - 1 && isAttached(kind.endBinding));
      paintVertexHandle(canvas, camera, point, isBound: isBound);
    }
  }

  /// Boxes the node a dragged line end will bind to, just clear of its own
  /// stroke.
  static void paintBindTarget(Canvas canvas, Camera camera, Node target) {
    canvas.drawRect(
      target.globalBounds().inflate(camera.screenLengthToWorldLength(10)),
      Paint()
        ..color = SquiggleColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = camera.screenLengthToWorldLength(2),
    );
  }

  static void paintSelectionBox(
    Canvas canvas,
    Camera camera,
    Rect worldBounds, {
    bool showResizeHandles = true,
  }) {
    final inflatedBounds = worldBounds.inflate(boxPadding);
    final worldHandleSize = camera.screenLengthToWorldLength(handleSize);
    final halfWorldHandleSize = worldHandleSize / 2;

    canvas.drawRect(
      inflatedBounds,
      Paint()
        ..color = SquiggleColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = camera.screenLengthToWorldLength(2),
    );
    if (!showResizeHandles) return;

    for (final center in [
      inflatedBounds.topLeft - Offset(halfWorldHandleSize, halfWorldHandleSize),
      inflatedBounds.topRight +
          Offset(halfWorldHandleSize, -halfWorldHandleSize),
      inflatedBounds.bottomLeft +
          Offset(-halfWorldHandleSize, halfWorldHandleSize),
      inflatedBounds.bottomRight +
          Offset(halfWorldHandleSize, halfWorldHandleSize),
    ]) {
      _paintSquareHandleAtWorldCenter(canvas, camera, center, worldHandleSize);
    }
  }

  /// A bound line end is drawn filled so attachment is visible at a glance.
  static void paintVertexHandle(
    Canvas canvas,
    Camera camera,
    Offset worldPoint, {
    bool isBound = false,
  }) {
    _paintCircleHandleAtWorldCenter(
      canvas,
      camera,
      worldPoint,
      fill: isBound ? SquiggleColors.accent : SquiggleColors.base,
    );
  }

  static void paintMarquee(Canvas canvas, Rect worldBounds) {
    canvas.drawRect(
      worldBounds,
      Paint()
        ..color = SquiggleColors.selectionFill
        ..style = PaintingStyle.fill,
    );
    paintDashedRect(canvas, worldBounds);
  }

  static void _paintSquareHandleAtWorldCenter(
    Canvas canvas,
    Camera camera,
    Offset center,
    double worldHandleSize,
  ) {
    final handleRRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: center,
        width: worldHandleSize,
        height: worldHandleSize,
      ),
      Radius.circular(camera.screenLengthToWorldLength(2)),
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
        ..strokeWidth = camera.screenLengthToWorldLength(2),
    );
  }

  static void _paintCircleHandleAtWorldCenter(
    Canvas canvas,
    Camera camera,
    Offset center, {
    required Color fill,
  }) {
    final radius = camera.screenLengthToWorldLength(handleSize / 2);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = fill
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = SquiggleColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = camera.screenLengthToWorldLength(2),
    );
  }
}
