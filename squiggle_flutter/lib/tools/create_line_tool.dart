import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_geometry.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/binding_candidate.dart';
import 'package:squiggle_flutter/tools/tool.dart';
import 'package:squiggle_flutter/tools/interaction_state.dart';
import 'package:squiggle_flutter/tools/create_line_tool/idle_state.dart';

class CreateLineTool extends Tool {
  late InteractionState<CreateLineTool> _activeInteractionState = IdleState(
    parent: this,
  );
  Feature? _previewFeature;
  BindingCandidate? hoveredBinding;

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
    hoveredBinding?.paint(canvas, camera);
  }

  void transition(
    InteractionState<CreateLineTool> state,
    EditorContext context,
  ) {
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
  bool onDoubleClick(
    EditorContext context,
    Offset worldPosition,
    Camera camera,
  ) {
    _activeInteractionState.onDoubleClick(context, worldPosition, camera);
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

  void finish(
    EditorContext context,
    List<Offset> points, {
    NodeBinding? startBinding,
    NodeBinding? endBinding,
  }) {
    if (points.length >= 2) {
      commit(
        context,
        points,
        startBinding: startBinding,
        endBinding: endBinding,
      );
    }
    _reset();
    context.resetToSelectTool();
  }

  void commit(
    EditorContext context,
    List<Offset> worldPoints, {
    NodeBinding? startBinding,
    NodeBinding? endBinding,
  }) {
    final feature = _previewFeature ?? _buildFeature(context, worldPoints);
    _setFeaturePoints(feature, worldPoints);
    final kind = feature.kind as FeatureKindPolyline;
    kind.startBinding = startBinding;
    kind.endBinding = endBinding;
    context.history.run('Create feature', (transaction) {
      transaction.add(feature);
    });
    context.selectCreatedFeature(feature);
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
    hoveredBinding = null;
  }

  Feature _buildFeature(EditorContext context, List<Offset> worldPoints) {
    final origin = worldPoints.first;
    final localPoints = localPointsFromWorld(worldPoints, origin);
    final kind = FeatureKindPolyline(localPoints);
    context.applyInspectorValues(kind);
    return Feature(origin: origin, size: Size.zero, kind: kind);
  }
}
