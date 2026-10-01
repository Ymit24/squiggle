import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool/interaction_state.dart';
import 'package:squiggle_flutter/tools/create_line_tool/idle_state.dart';

class CreateLineTool extends Tool {
  late InteractionState _activeInteractionState = IdleState(parent: this);
  Feature? _previewFeature;

  @override
  EditorCursor resolveCursor(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) => EditorCursor.crosshair;

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {
    _previewFeature?.paint(canvas, imageRepository);
  }

  void transition(InteractionState state, EditorContext context) {
    _activeInteractionState = state;
    state.onEnter(context);
  }

  @override
  void deactivate(EditorContext context) => cancelInteraction(context);

  @override
  void cancelInteraction(EditorContext context) {
    _reset();
  }

  @override
  bool onPointerDown(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _activeInteractionState.onPointerDown(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
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
    _activeInteractionState.onPointerMove(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
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
    _activeInteractionState.onPointerUp(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    return true;
  }

  @override
  bool onPointerHover(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    _activeInteractionState.onPointerHover(
      context,
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );
    return true;
  }

  @override
  bool onKeyEvent(EditorContext context, KeyDownEvent event) {
    return _activeInteractionState.onKeyEvent(context, event);
  }

  Offset constrainedPoint(
    Offset origin,
    Offset point, {
    required bool isShiftPressed,
  }) => isShiftPressed ? snapPointTo45DegreeAngle(origin, point) : point;

  void finishPlacing(EditorContext context, List<Offset> points) {
    if (points.length >= 2) {
      commit(context, points);
    }
    _reset();
  }

  void commit(EditorContext context, List<Offset> worldPoints) {
    final feature = _previewFeature ?? _buildFeature(context, worldPoints);
    _setFeaturePoints(feature, worldPoints);
    context.history.run('Create feature', (transaction) {
      transaction.add(feature);
    });
  }

  void updatePreview(EditorContext context, List<Offset> worldPoints) {
    final feature = _previewFeature ??= _buildFeature(context, worldPoints);
    _setFeaturePoints(feature, worldPoints);
  }

  void _setFeaturePoints(Feature feature, List<Offset> worldPoints) {
    (feature.kind as FeatureKindPolyline).setGeometry(
      feature,
      origin: worldPoints.first,
      localPoints: localPointsFromWorld(worldPoints, worldPoints.first),
    );
  }

  void _reset() {
    _activeInteractionState = IdleState(parent: this);
    _previewFeature = null;
  }

  Feature _buildFeature(EditorContext context, List<Offset> worldPoints) {
    final origin = worldPoints.first;
    final localPoints = localPointsFromWorld(worldPoints, origin);
    final kind = FeatureKindPolyline(localPoints);
    context.applyInspectorValues(kind);
    return Feature(origin: origin, size: Size.zero, kind: kind);
  }
}
