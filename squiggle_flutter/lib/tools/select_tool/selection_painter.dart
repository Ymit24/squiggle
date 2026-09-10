import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
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
    for (final featureId in context.selection.selectedNodes) {
      final feature = context.document.featureById(featureId);
      if (feature != null) {
        paintSelectionBox(canvas, camera, feature.bounds());
      }
    }
  }

  static void paintSelectedPolylineHandles(
    Canvas canvas,
    Camera camera,
    EditorContext context,
  ) {
    if (context.selection.selectedNodes.length != 1) return;

    final selectedId = context.selection.selectedNodes.single;
    final feature = context.document.featureById(selectedId);
    if (feature == null || feature.kind is! FeatureKindPolyline) return;

    final kind = feature.kind as FeatureKindPolyline;
    for (final point in worldPoints(feature.origin, kind.localPoints)) {
      paintVertexHandle(canvas, camera, point);
    }
  }

  static void paintSelectionBox(
    Canvas canvas,
    Camera camera,
    Rect worldBounds,
  ) {
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

  static void paintVertexHandle(
    Canvas canvas,
    Camera camera,
    Offset worldPoint,
  ) {
    _paintCircleHandleAtWorldCenter(canvas, camera, worldPoint);
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
    Offset center,
  ) {
    final radius = camera.screenLengthToWorldLength(handleSize / 2);
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
        ..strokeWidth = camera.screenLengthToWorldLength(2),
    );
  }
}
