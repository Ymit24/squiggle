import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/models/commands/command.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';

class TextEditBloc extends Bloc<TextEditEvent, TextEditState> {
  TextEditBloc({
    required this.documentRepository,
    required this.textEditRepository,
  }) : super(const TextEditClosed()) {
    on<RequestWatchTextEditStateEvent>(_onRequestWatchTextEditState);
    on<TextEditSubmitted>(_onTextEditSubmitted);
    on<TextEditCancelled>(_onTextEditCancelled);
  }

  final DocumentRepository documentRepository;
  final TextEditRepository textEditRepository;

  Future<void> _onRequestWatchTextEditState(
    RequestWatchTextEditStateEvent event,
    Emitter<TextEditState> emit,
  ) async {
    await emit.forEach(
      textEditRepository.editSessionStream,
      onData: (session) => TextEditOpen(
        featureId: session.featureId,
        initialContents: session.initialContents,
        canvasLocalBounds: session.canvasLocalBounds,
      ),
    );
  }

  void _onTextEditSubmitted(
    TextEditSubmitted event,
    Emitter<TextEditState> emit,
  ) {
    final current = state;
    if (current is! TextEditOpen) return;

    documentRepository.executeCommand(
      UpdateTextContentsCommand(current.featureId, event.contents),
    );
    emit(const TextEditClosed());
  }

  void _onTextEditCancelled(
    TextEditCancelled event,
    Emitter<TextEditState> emit,
  ) {
    emit(const TextEditClosed());
  }
}
