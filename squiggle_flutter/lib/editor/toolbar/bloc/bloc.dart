import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/event.dart';
import 'package:squiggle_flutter/editor/toolbar/bloc/state.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';
import 'package:squiggle_flutter/tools/create_feature_tool.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/create_text_tool.dart';
import 'package:squiggle_flutter/tools/select_tool.dart';

class ToolbarBloc extends Bloc<ToolbarEvent, ToolbarState> {
  ToolbarBloc({
    required ToolRepository toolRepository,
    required SelectionRepository selectionRepository,
    required DocumentRepository documentRepository,
  }) : // Public named parameters keep call sites readable while fields stay private.
       // ignore: prefer_initializing_formals
       _toolRepository = toolRepository,
       // ignore: prefer_initializing_formals
       _selectionRepository = selectionRepository,
       // ignore: prefer_initializing_formals
       _documentRepository = documentRepository,
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

  final ToolRepository _toolRepository;
  final SelectionRepository _selectionRepository;
  final DocumentRepository _documentRepository;

  Future<void> _onRequestWatchToolbarState(
    RequestWatchToolbarStateEvent event,
    Emitter<ToolbarState> emit,
  ) async {
    emit(_stateWithHistory(state));

    await emit.forEach(
      _documentRepository.changesStream,
      onData: (_) => _stateWithHistory(state),
    );
  }

  void _onActivateSelectTool(
    ActivateSelectToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _toolRepository.setTool(SelectTool(), _selectionRepository);
    emit(state.copyWith(activeTool: ActiveToolKind.select));
  }

  void _onActivateCreateRectTool(
    ActivateCreateRectToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _toolRepository.setTool(CreateFeatureTool.rect(), _selectionRepository);
    emit(state.copyWith(activeTool: ActiveToolKind.createRect));
  }

  void _onActivateCreateCircleTool(
    ActivateCreateCircleToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _toolRepository.setTool(CreateFeatureTool.circle(), _selectionRepository);
    emit(state.copyWith(activeTool: ActiveToolKind.createCircle));
  }

  void _onActivateCreateLineTool(
    ActivateCreateLineToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _toolRepository.setTool(CreateLineTool(), _selectionRepository);
    emit(state.copyWith(activeTool: ActiveToolKind.createLine));
  }

  void _onActivateCreateTextTool(
    ActivateCreateTextToolEvent event,
    Emitter<ToolbarState> emit,
  ) {
    _toolRepository.setTool(CreateTextTool(), _selectionRepository);
    emit(state.copyWith(activeTool: ActiveToolKind.createText));
  }

  void _onUndoDocument(UndoDocumentEvent event, Emitter<ToolbarState> emit) {
    _documentRepository.undo();
  }

  void _onRedoDocument(RedoDocumentEvent event, Emitter<ToolbarState> emit) {
    _documentRepository.redo();
  }

  ToolbarState _stateWithHistory(ToolbarState state) {
    return state.copyWith(
      canUndo: _documentRepository.canUndo,
      canRedo: _documentRepository.canRedo,
    );
  }
}
