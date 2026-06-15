import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/models/commands/command.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
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
      onData: (session) => switch (session) {
        EditTextEditSession(
          :final featureId,
          :final initialContents,
          :final canvasLocalBounds,
        ) =>
          EditTextEditOpen(
            featureId: featureId,
            initialContents: initialContents,
            canvasLocalBounds: canvasLocalBounds,
          ),
        CreateTextEditSession(
          :final worldOrigin,
          :final initialContents,
          :final canvasLocalBounds,
        ) =>
          CreateTextEditOpen(
            worldOrigin: worldOrigin,
            initialContents: initialContents,
            canvasLocalBounds: canvasLocalBounds,
          ),
      },
    );
  }

  void _onTextEditSubmitted(
    TextEditSubmitted event,
    Emitter<TextEditState> emit,
  ) {
    final current = state;
    if (current is! TextEditOpen) return;

    switch (current) {
      case EditTextEditOpen(:final featureId):
        documentRepository.executeCommand(
          UpdateTextContentsCommand(featureId, event.contents),
        );
      case CreateTextEditOpen(:final worldOrigin):
        if (event.contents.isNotEmpty) {
          documentRepository.executeCommand(
            AddFeatureCommand(
              newTextFeatureAt(worldOrigin, event.contents).copyWith(id: noId),
            ),
          );
        }
    }
    emit(const TextEditClosed());
  }

  void _onTextEditCancelled(
    TextEditCancelled event,
    Emitter<TextEditState> emit,
  ) {
    emit(const TextEditClosed());
  }
}
