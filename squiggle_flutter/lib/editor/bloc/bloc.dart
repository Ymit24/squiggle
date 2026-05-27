import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/bloc/state.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';
import 'package:squiggle_flutter/repositories/tool_repository.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  EditorBloc({
    required this.documentRepository,
    required this.selectionRepository,
    required this.toolRepository,
  }) : super(EditorState.empty(documentRepository.document)) {
    on<RequestWatchEditorStateEvent>(_onRequestWatchEditorState);
  }

  final DocumentRepository documentRepository;
  final SelectionRepository selectionRepository;
  final ToolRepository toolRepository;

  Future<void> _onRequestWatchEditorState(
    RequestWatchEditorStateEvent event,
    Emitter<EditorState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedFeatures: List.of(selectionRepository.selectedFeatures),
      ),
    );

    await Future.wait([
      emit.forEach(
        selectionRepository.selectedFeaturesStream,
        onData: (selectedFeatures) => state.copyWith(
          selectedFeatures: List.of(selectedFeatures),
        ),
      ),
      emit.forEach(
        documentRepository.changesStream,
        onData: (_) =>
            state.copyWith(document: documentRepository.document),
      ),
    ]);
  }
}
