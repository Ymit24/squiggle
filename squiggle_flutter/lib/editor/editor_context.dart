import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/editor/tool_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/tools/tool.dart';

/// Top-level editor state, owned by the document UI and passed around to
/// tools, render objects, blocs, and services.
///
/// Observers may listen to the whole context (anything changed) or to the
/// individual sub-models exposed below.
class EditorContext extends ChangeNotifier {
  EditorContext({
    required this.document,
    SelectionModel? selection,
    ToolModel? tool,
    CommandHistory? history,
    TextEditModel? textEdit,
  }) : _selection = selection ?? SelectionModel(),
       _tool = tool ?? ToolModel(),
       _history = history ?? CommandHistory(document: document),
       _textEdit = textEdit ?? TextEditModel() {
    _selection.addListener(_forward);
    _tool.addListener(_forward);
    _history.addListener(_forward);
    _textEdit.addListener(_forward);
  }

  final Document document;
  final SelectionModel _selection;
  final ToolModel _tool;
  final CommandHistory _history;
  final TextEditModel _textEdit;

  SelectionModel get selection => _selection;

  ToolModel get tool => _tool;

  CommandHistory get history => _history;

  TextEditModel get textEdit => _textEdit;

  /// World-space camera for the current document viewport.
  final Camera camera = Camera();

  /// Viewport size in screen pixels, written by the viewport widget.
  Size viewportSize = Size.zero;

  void _forward() => notifyListeners();

  /// Notifies observers that the camera or viewport changed.
  void notifyViewportChanged() => notifyListeners();

  /// World point at the center of the current viewport, if known.
  Offset? worldCenterAtViewportCenter() {
    if (viewportSize == Size.zero) return null;
    return camera.screenToWorld(viewportSize.center(Offset.zero));
  }

  void execute(Command command) => history.execute(command);

  void record(Command command) => history.record(command);

  void undo() => history.undo();

  void redo() => history.redo();

  void setTool(Tool tool) => _tool.setTool(tool, this);

  void startTextEdit(TextEditSession session) => _textEdit.begin(session);

  void endTextEdit() => _textEdit.end();

  /// Removes the selected features as one undoable edit.
  void deleteSelection() {
    final ids = List<FeatureId>.of(selection.selectedFeatures);
    if (ids.isEmpty) return;
    execute(RemoveFeaturesCommand(ids));
    selection.clearSelection();
  }

  /// Replaces the document contents and resets transient state.
  void loadDocument(Document newDocument) {
    document.replaceFrom(newDocument);
    history.clear();
    selection.clearSelection();
    endTextEdit();
  }

  @override
  void dispose() {
    _selection.removeListener(_forward);
    _tool.removeListener(_forward);
    _history.removeListener(_forward);
    _textEdit.removeListener(_forward);
    super.dispose();
  }
}
