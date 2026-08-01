import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/select_tool.dart';

class ToolbarBloc extends Bloc<ToolbarEvent, ToolbarState> {
  ToolbarBloc({required EditorContext context})
    : // Public named parameters keep call sites readable while fields stay private.
       // ignore: prefer_initializing_formals
       _context = context,
       super(const ToolbarState(activeTool: ActiveToolKind.select)) {
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
    emit(state.copyWith(activeTool: ActiveToolKind.select));
  }

  void _onActivateCreateRectTool(
    ActivateCreateRectToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _context.setTool(CreateFeatureTool.rect());
    emit(state.copyWith(activeTool: ActiveToolKind.createRect));
  }

  void _onActivateCreateCircleTool(
    ActivateCreateCircleToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _context.setTool(CreateFeatureTool.circle());
    emit(state.copyWith(activeTool: ActiveToolKind.createCircle));
  }

  void _onActivateCreateLineTool(
    ActivateCreateLineToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _context.setTool(CreateLineTool());
    emit(state.copyWith(activeTool: ActiveToolKind.createLine));
  }

  void _onActivateCreateTextTool(
    ActivateCreateTextToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _context.setTool(CreateTextTool());
    emit(state.copyWith(activeTool: ActiveToolKind.createText));
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
