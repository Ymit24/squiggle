import 'dart:async';

import 'package:flutter/services.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';
import 'package:squiggle_flutter/tools/editor_cursor.dart';
import 'package:squiggle_flutter/tools/select_tool.dart';
import 'package:squiggle_flutter/tools/tool.dart';

class ToolRepository {
  ToolRepository({Tool? initialTool})
    : _activeTool = initialTool ?? SelectTool();

  Tool _activeTool;

  final _repaintController = StreamController<void>.broadcast();

  Stream<void> get repaintStream => _repaintController.stream;

  Tool get activeTool => _activeTool;

  void setTool(Tool tool, SelectionRepository selection) {
    _activeTool.deactivate(selection);
    _activeTool = tool;
    _notifyRepaint();
  }

  void onPointerDown(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    Camera camera,
  ) {
    _activeTool.onPointerDown(
      documentRepository,
      worldPosition,
      selection,
      isShiftPressed,
      camera,
    );
    _notifyRepaint();
  }

  void onPointerMove(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    Camera camera,
  ) {
    _activeTool.onPointerMove(
      documentRepository,
      worldPosition,
      selection,
      isShiftPressed,
      camera,
    );
    _notifyRepaint();
  }

  EditorCursor resolveCursor(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    Camera camera,
  ) {
    return _activeTool.resolveCursor(
      documentRepository,
      worldPosition,
      selection,
      camera,
    );
  }

  void onPointerUp(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    Camera camera,
    TextEditRepository textEditRepository,
  ) {
    _activeTool.onPointerUp(
      documentRepository,
      worldPosition,
      selection,
      isShiftPressed,
      camera,
      textEditRepository,
    );
    _notifyRepaint();
  }

  void onPointerHover(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
    Camera camera,
  ) {
    _activeTool.onPointerHover(
      documentRepository,
      worldPosition,
      selection,
      isShiftPressed,
      camera,
    );
    _notifyRepaint();
  }

  bool onKeyEvent(
    DocumentRepository documentRepository,
    KeyDownEvent event,
  ) {
    final handled = _activeTool.onKeyEvent(documentRepository, event);
    if (handled) {
      _notifyRepaint();
    }
    return handled;
  }

  void _notifyRepaint() {
    _repaintController.add(null);
  }

  void dispose() {
    _repaintController.close();
  }
}
