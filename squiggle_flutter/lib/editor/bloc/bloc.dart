import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/bloc/state.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/node.dart';

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
    final nodes = context.selection.selectedFeatures
        .map(context.document.nodeById)
        .whereType<Node>()
        .toList();
    if (nodes.isEmpty) return;

    final container = nodes.first.parent;
    if (container == null ||
        nodes.any((node) => !identical(node.parent, container))) {
      throw StateError('Selected nodes must share a container');
    }

    context.cancelInteraction();
    context.history.run(
      'Delete selection',
      (transaction) => transaction.removeAll(nodes.map((node) => node.id)),
      container: container,
    );
    context.selection.clearSelection();
  }
}
