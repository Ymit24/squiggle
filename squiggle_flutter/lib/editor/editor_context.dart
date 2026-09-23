import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/editor/history/history.dart';
import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/editor/tool_model.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
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
    History? history,
    TextEditModel? textEdit,
  }) : _selection = selection ?? SelectionModel(),
       _tool = tool ?? ToolModel(),
       _history = history ?? History(document: document),
       _textEdit = textEdit ?? TextEditModel() {
    _selection.addListener(_forward);
    _tool.addListener(_forward);
    _history.addListener(_forward);
    _textEdit.addListener(_forward);
  }

  final Document document;
  final SelectionModel _selection;
  final ToolModel _tool;
  final History _history;
  final TextEditModel _textEdit;
  final Map<String, Object?> _inspectorValues = {};

  SelectionModel get selection => _selection;

  ToolModel get tool => _tool;

  History get history => _history;

  TextEditModel get textEdit => _textEdit;

  /// World-space camera for the current document viewport.
  final Camera camera = Camera();

  /// Viewport size in screen pixels, written by the viewport widget.
  Size viewportSize = Size.zero;

  // TODO: Consider a better way to coordinate camera motion.
  VoidCallback? _cancelViewportMotion;

  void attachViewportMotionCanceller(VoidCallback cancel) {
    _cancelViewportMotion = cancel;
  }

  void detachViewportMotionCanceller(VoidCallback cancel) {
    if (_cancelViewportMotion == cancel) _cancelViewportMotion = null;
  }

  void cancelViewportMotion() => _cancelViewportMotion?.call();

  void _forward() => notifyListeners();

  /// Notifies observers that the camera or viewport changed.
  void notifyViewportChanged() => notifyListeners();

  /// World point at the center of the current viewport, if known.
  Offset? worldCenterAtViewportCenter() {
    if (viewportSize == Size.zero) return null;
    return camera.screenToWorld(viewportSize.center(Offset.zero));
  }

  void cancelInteraction() {
    tool.activeTool.cancelInteraction(this);
  }

  void undo() {
    cancelInteraction();
    if (!history.canUndo) return;
    history.undo();
    _refreshSelectionAfterHistoryChange();
  }

  void redo() {
    cancelInteraction();
    if (!history.canRedo) return;
    history.redo();
    _refreshSelectionAfterHistoryChange();
  }

  void _refreshSelectionAfterHistoryChange() {
    selection.setSelection(
      selection.selectedNodeIds.where((id) => document.nodeById(id) != null),
    );
  }

  void setTool(Tool tool) => _tool.setTool(tool, this);

  void startTextEdit(TextEditSession session) => _textEdit.begin(session);

  void endTextEdit() => _textEdit.end();

  void rememberInspectorValue(String fieldKey, Object? value) {
    _inspectorValues[fieldKey] = value;
  }

  /// Applies the last inspector choices to a feature being created.
  void applyInspectorValues(Feature feature) {
    for (final field in feature.kind.buildInspectorFields()) {
      if (_inspectorValues.containsKey(field.fieldKey)) {
        field.applyIfCompatible(_inspectorValues[field.fieldKey]);
      }
    }
    if (feature.kind case FeatureKindText kind) {
      feature.size = kind.measureContents(
        width: defaultNewTextWidth,
        fontSize: kind.fontSize,
      );
    }
  }

  Rect newTextBoundsAt(Offset origin) {
    final feature = newTextFeatureAt(origin, '');
    applyInspectorValues(feature);
    return feature.localBounds();
  }

  /// Replaces the document contents and resets transient state.
  void loadDocument(Document newDocument) {
    cancelInteraction();
    document.replaceFrom(newDocument);
    history.clear();
    _inspectorValues.clear();
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
