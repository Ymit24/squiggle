import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/utils/painting.dart';

import 'marquee_interaction.dart';
import 'select_hit_test.dart';
import 'select_interaction.dart';

const kSelectionHandlePaintSize = 12.0;

/// Renders Select-specific overlays: selection boxes and resize handles,
/// polyline vertex handles, and the marquee rectangle.
class SelectOverlay {
  const SelectOverlay();

  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context, {
    SelectInteraction? interaction,
    FeatureId? editingFeatureId,
  }) {
    final document = context.document;

    for (final featureId in context.selection.selectedFeatures) {
      final feature = document.featureById(featureId);
      if (feature != null) {
        _paintSelectionBox(canvas, camera, feature.bounds());
      }
    }

    if (editingFeatureId != null) {
      final feature = document.featureById(editingFeatureId);
      if (feature != null && feature.kind is FeatureKindPolyline) {
        final kind = feature.kind as FeatureKindPolyline;
        for (final point in worldPoints(feature.origin, kind.localPoints)) {
          _paintCircleHandle(canvas, camera, point);
        }
      }
    }

    if (interaction is MarqueeInteraction) {
      final worldBounds = Rect.fromPoints(interaction.start, interaction.end);
      canvas.drawRect(
        worldBounds,
        Paint()
          ..color = SquiggleColors.selectionFill
          ..style = PaintingStyle.fill,
      );
      paintDashedRect(canvas, worldBounds);
    }
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

  void _paintCircleHandle(Canvas canvas, Camera camera, Offset worldPoint) {
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
}