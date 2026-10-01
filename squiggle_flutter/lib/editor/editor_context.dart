import 'package:flutter/cupertino.dart';
import 'package:squiggle_flutter/editor/history/history.dart';
import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/editor/tool_model.dart';
import 'package:squiggle_flutter/editor/widgets/context_menu.dart';
import 'package:squiggle_flutter/models/camera.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/tools/tool.dart';
import 'package:squiggle_flutter/widgets/squiggle_context_menu.dart';

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

  /// Persisted session changes are separate from pointer/camera notifications.
  final ChangeNotifier sessionChanges = ChangeNotifier();
  int _brushSequence = 0;

  void openContextMenuAt(
    BuildContext context,
    Offset localScreenPosition,
    Offset worldPosition, {
    required ImageRepository imageRepository,
  }) {
    final node = document.nodeAtPoint(worldPosition);
    if (node != null && !selection.isNodeSelected(node.id)) {
      selection.setSelection([node.id]);
    }

    showSquiggleContextMenu(
      context: context,
      builder: (_) => ContextMenu(
        localScreenPosition: localScreenPosition,
        editorContext: this,
        imageRepository: imageRepository,
      ),
    );
  }

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

  BrushProfile get activeBrush => document.session.activeBrush;

  void activateBrush(String id) {
    if (document.session.activeBrushId == id) return;
    if (!document.session.brushes.any((brush) => brush.id == id)) return;
    document.session.activeBrushId = id;
    _sessionChanged();
  }

  BrushProfile createBrush(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError.value(name, 'name');
    String id;
    do {
      id = 'brush-${DateTime.now().microsecondsSinceEpoch}-${_brushSequence++}';
    } while (document.session.brushes.any((brush) => brush.id == id));
    final brush = BrushProfile(
      id: id,
      name: trimmed,
      values: activeBrush.values,
    );
    document.session.brushes.add(brush);
    document.session.activeBrushId = brush.id;
    _sessionChanged();
    return brush;
  }

  void renameBrush(String id, String name) {
    final brush = document.session.brushes
        .where((brush) => brush.id == id)
        .firstOrNull;
    if (brush == null || brush.isScratch || name.trim().isEmpty) return;
    brush.name = name.trim();
    _sessionChanged();
  }

  void deleteBrush(String id) {
    final brush = document.session.brushes
        .where((brush) => brush.id == id)
        .firstOrNull;
    if (brush == null || brush.isScratch) return;
    if (activeBrush.id == id) {
      document.session.scratch.values
        ..clear()
        ..addAll(brush.values);
      document.session.activeBrushId = BrushProfile.scratchId;
    }
    document.session.brushes.remove(brush);
    _sessionChanged();
  }

  void setDrawingField(String key, Object? value) {
    activeBrush.values[key] = value;
    _sessionChanged();
  }

  void clearDrawingField(String key) {
    if (!activeBrush.values.containsKey(key)) return;
    activeBrush.values.remove(key);
    _sessionChanged();
  }

  void _sessionChanged() {
    sessionChanges.notifyListeners();
    notifyListeners();
  }

  /// Kept as an alias for creation call sites; selection edits never call this.
  void rememberInspectorValue(String fieldKey, Object? value) =>
      setDrawingField(fieldKey, value);

  void applyInspectorValues(FeatureKind kind) => activeBrush.applyTo(kind);

  /// Fresh defaults for the active creation tool, never its mutable template.
  FeatureKind? get drawingInspectorKind {
    final kind = switch (tool.activeTool) {
      CreateFeatureTool(:final kind) => kind.clone(),
      CreateLineTool() => FeatureKindPolyline([]),
      CreateTextTool() => FeatureKindText(''),
      _ => null,
    };
    if (kind != null) activeBrush.applyTo(kind);
    return kind;
  }

  /// Replaces the document contents and resets transient state.
  void loadDocument(Document newDocument) {
    cancelInteraction();
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
    sessionChanges.dispose();
    super.dispose();
  }
}
