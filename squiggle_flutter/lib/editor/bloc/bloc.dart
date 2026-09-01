import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/bloc/state.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  EditorBloc({required this.context})
    : super(EditorState.empty(context.document)) {
    on<RequestWatchEditorStateEvent>(_onRequestWatchEditorState);
    on<DeleteSelectedFeaturesEvent>(_onDeleteSelectedFeatures);
  }

  final EditorContext context;

  Future<void> _onRequestWatchEditorState(
    RequestWatchEditorStateEvent event,
    Emitter<EditorState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedFeatures: List.of(context.selection.selectedFeatures),
      ),
    );

    await emit.forEach(
      notifierChangesStream(context),
      onData: (_) => EditorState(
        document: context.document,
        selectedFeatures: List.of(context.selection.selectedFeatures),
      ),
    );
  }

  void _onDeleteSelectedFeatures(
    DeleteSelectedFeaturesEvent event,
    Emitter<EditorState> emit,
  ) {
    context.deleteSelection();
  }
}
