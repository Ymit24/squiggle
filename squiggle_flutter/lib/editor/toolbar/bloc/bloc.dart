import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

class ToolbarBloc extends Bloc<ToolbarEvent, ToolbarState> {
  ToolbarBloc({required EditorContext context})
    : // Public named parameters keep call sites readable while fields stay private.
      // ignore: prefer_initializing_formals
      _context = context,
      super(const ToolbarState()) {
    on<RequestWatchToolbarStateEvent>(_onRequestWatchToolbarState);
    on<ActivateSelectToolEvent>(_onActivateSelectTool);
    on<ActivateCreateRectToolEvent>(_onActivateCreateRectTool);
    on<ActivateCreateCircleToolEvent>(_onActivateCreateCircleTool);
    on<ActivateCreateLineToolEvent>(_onActivateCreateLineTool);
    on<ActivateCreateTextToolEvent>(_onActivateCreateTextTool);
    on<UndoDocumentEvent>(_onUndoDocument);
    on<RedoDocumentEvent>(_onRedoDocument);
  }

  final EditorContext _context;

  Future<void> _onRequestWatchToolbarState(
    RequestWatchToolbarStateEvent event,
    Emitter<ToolbarState> emit,
  ) async {
    emit(_stateWithHistory(state));

    await emit.forEach(
      notifierChangesStream(_context.history),
      onData: (_) => _stateWithHistory(state),
    );
  }

  void _onActivateSelectTool(
    ActivateSelectToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _context.setTool(SelectTool());
  }

  void _onActivateCreateRectTool(
    ActivateCreateRectToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _context.setTool(CreateFeatureTool.rect());
  }

  void _onActivateCreateCircleTool(
    ActivateCreateCircleToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _context.setTool(CreateFeatureTool.circle());
  }

  void _onActivateCreateLineTool(
    ActivateCreateLineToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _context.setTool(CreateLineTool());
  }

  void _onActivateCreateTextTool(
    ActivateCreateTextToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _context.setTool(CreateTextTool());
  }

  void _onUndoDocument(UndoDocumentEvent event, Emitter<ToolbarState> emit) {
    _context.undo();
  }

  void _onRedoDocument(RedoDocumentEvent event, Emitter<ToolbarState> emit) {
    _context.redo();
  }

  ToolbarState _stateWithHistory(ToolbarState state) {
    return state.copyWith(
      canUndo: _context.history.canUndo,
      canRedo: _context.history.canRedo,
    );
  }
}
