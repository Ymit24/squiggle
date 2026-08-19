import 'dart:ui';

import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/camera.dart';

/// A transient pointer interaction that runs while [SelectTool] is active.
///
/// Each interaction owns its gesture state and transaction lifecycle:
///
/// ```text
/// begin (construction) → update → commit / cancel
/// ```
///
/// `update` mutates the document live for visual feedback; `commit` records a
/// single undoable command once the gesture completes.
abstract class SelectInteraction {
  const SelectInteraction();

  void update(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  });

  void commit(
    EditorContext context,
    Offset worldPosition,
    Camera camera, {
    required bool isShiftPressed,
    required bool isAltPressed,
  });

  void cancel(EditorContext context) {}
}