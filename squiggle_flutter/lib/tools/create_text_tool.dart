import 'dart:ui';

import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/tool.dart';

class CreateTextTool extends Tool {
  @override
  EditorCursor resolveCursor(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    Camera camera,
  ) =>
      EditorCursor.crosshair;

  @override
  void paint(
    Canvas canvas,
    Camera camera,
    DocumentRepository documentRepository,
    SelectionRepository selection,
  ) {}

  @override
  void deactivate(SelectionRepository selection) {}

  @override
  void onPointerDown(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    bool isAltPressed,
    Camera camera,
  ) {}

  @override
  void onPointerMove(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    bool isAltPressed,
    Camera camera,
  ) {}

  @override
  void onPointerUp(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    bool isAltPressed,
    Camera camera,
    TextEditRepository textEditRepository,
  ) {
    textEditRepository.beginEdit(
      CreateTextEditSession(
        worldOrigin: worldPosition,
        initialContents: '',
        canvasLocalBounds: camera.worldToScreenBounds(
          newTextBoundsAt(worldPosition),
        ),
      ),
    );
  }
}
