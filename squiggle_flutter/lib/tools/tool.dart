import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';

/// Active editor tool: pointer handling and ephemeral overlay painting.
abstract class Tool {
  const Tool();

  /// Paints tool-specific overlays after the world transform is applied.
  ///
  /// Most overlays are world-space; selection and edit handles use [camera] for
  /// screen-constant sizing.
  void paint(
    Canvas canvas,
    Camera camera,
    DocumentRepository documentRepository,
    SelectionRepository selection,
  );

  void onPointerDown(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    bool isAltPressed,
    Camera camera,
  );

  void onPointerMove(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    bool isAltPressed,
    Camera camera,
  );

  void onPointerUp(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    bool isAltPressed,
    Camera camera,
    TextEditRepository textEditRepository,
  );

  void deactivate(SelectionRepository selection);

  void onPointerHover(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    bool isAltPressed,
    Camera camera,
  ) {}

  bool onKeyEvent(
    DocumentRepository documentRepository,
    KeyDownEvent event,
  ) =>
      false;

  EditorCursor resolveCursor(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    Camera camera,
  ) =>
      EditorCursor.basic;
}
