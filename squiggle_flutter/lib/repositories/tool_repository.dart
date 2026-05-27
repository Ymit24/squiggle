import 'dart:async';
import 'dart:ui';

import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
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
  ) {
    _activeTool.onPointerDown(
      documentRepository,
      worldPosition,
      selection,
      isShiftPressed,
    );
    _notifyRepaint();
  }

  void onPointerMove(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
  ) {
    _activeTool.onPointerMove(
      documentRepository,
      worldPosition,
      selection,
      isShiftPressed,
    );
    _notifyRepaint();
  }

  void onPointerUp(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
  ) {
    _activeTool.onPointerUp(
      documentRepository,
      worldPosition,
      selection,
      isShiftPressed,
    );
    _notifyRepaint();
  }

  void _notifyRepaint() {
    _repaintController.add(null);
  }

  void dispose() {
    _repaintController.close();
  }
}
