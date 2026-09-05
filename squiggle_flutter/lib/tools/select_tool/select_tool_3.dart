import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';
import 'package:squiggle_flutter/tools/tool.dart';

class SelectTool extends Tool {
  late InteractionState _activeInteractionState = IdleInteractionState(
    parent: this,
  );

  void transition(InteractionState state) {
    _activeInteractionState = state;
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
      CanvasTarget(),
      worldPosition,
      camera,
      isShiftPressed: isShiftPressed,
      isAltPressed: isAltPressed,
    );

    // TODO: Update how change detection works to not be bool response based.
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
    // TODO: Update how change detection works to not be bool response based.
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
    // TODO: Update how change detection works to not be bool response based.
    return true;
  }

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    EditorContext context,
    ImageRepository imageRepository,
  ) {}
}

abstract class InteractionState {
  final SelectTool parent;

  InteractionState({required this.parent});

  void onPointerDown(
    EditorContext context,
    HitTarget target,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}

  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {}
}

class HitTarget {}

class CanvasTarget extends HitTarget {}

class FeatureTarget extends HitTarget {
  final Feature feature;

  FeatureTarget({required this.feature});
}

class HandleTarget extends HitTarget {
  final SelectionResizeHandle handle;

  HandleTarget({required this.handle});
}

class IdleInteractionState extends InteractionState {
  IdleInteractionState({required super.parent});

  @override
  void onPointerDown(
    EditorContext context,
    HitTarget target,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    switch (target) {
      case HandleTarget():
        // parent.transition("resize");
        break;
      case FeatureTarget(feature: var chaseFeature):
        final selectedFeatures = context.selection.selectedFeatures.map(
          (id) => context.document.featureById(id),
        );
        if (selectedFeatures.any((f) => f == null)) {
          // TODO: Is this possible? What to do?
          return;
        }
        parent.transition(
          ClickFeatureState(
            parent: parent,
            start: cursorWorldPosition,
            chase: chaseFeature,
            selectedFeatures: selectedFeatures.map((f) => f!).toList(),
          ),
        );
        break;
      case CanvasTarget():
        // parent.transition();
        break;
    }
  }
}

class ClickFeatureState extends InteractionState {
  ClickFeatureState({
    required super.parent,
    required this._start,
    required this._chase,
    required this._selectedFeatures,
  });

  final Offset _start;
  final Feature _chase;
  final List<Feature> _selectedFeatures;

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    if (isAltPressed) {
      parent.transition(
        DuplicateState(
          parent: parent,
          chase: _chase,
          selectedFeatures: _selectedFeatures,
          start: _start,
        ),
      );
    } else {
      parent.transition(
        TranslateState(
          parent: parent,
          chase: _chase,
          selectedFeatures: _selectedFeatures,
          start: _start,
        ),
      );
    }
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    parent.transition(IdleInteractionState(parent: parent));
  }
}

class DuplicateState extends InteractionState {
  DuplicateState({
    required super.parent,
    required this._start,
    required this._chase,
    required this._selectedFeatures,
  });

  final Offset _start;
  final Feature _chase;
  final List<Feature> _selectedFeatures;

  void onEnter(EditorContext context) {
    final cloneFeatures = _selectedFeatures
        .map((f) => f.copyWith(id: noId))
        .toList();
    context.document.addFeatures(cloneFeatures);

    parent.transition(
      TranslateState(
        parent: parent,
        start: _start,
        chase: _chase,
        selectedFeatures: cloneFeatures,
      ),
    );
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    parent.transition(IdleInteractionState(parent: parent));
  }
}

class TranslateState extends InteractionState {
  TranslateState({
    required super.parent,
    required this._start,
    required Feature chase,
    required this._selectedFeatures,
  }) {
    _initialOrigins = {
      for (final feature in _selectedFeatures) feature.id: feature.origin,
    };
  }

  final Offset _start;
  final List<Feature> _selectedFeatures;
  late final Map<FeatureId, Offset> _initialOrigins;

  @override
  void onPointerMove(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    final totalMotion = cursorWorldPosition - _start;

    for (var feature in _selectedFeatures) {
      feature.origin = _initialOrigins[feature.id]! + totalMotion;
    }
  }

  @override
  void onPointerUp(
    EditorContext context,
    Offset cursorWorldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  }) {
    parent.transition(IdleInteractionState(parent: parent));
  }
}
