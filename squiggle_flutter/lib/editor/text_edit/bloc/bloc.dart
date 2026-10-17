import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';

class TextEditBloc extends Bloc<TextEditEvent, TextEditState> {
  TextEditBloc({required this.context}) : super(const TextEditClosed()) {
    on<RequestWatchTextEditStateEvent>(_onRequestWatchTextEditState);
  }

  final EditorContext context;

  Future<void> _onRequestWatchTextEditState(
    RequestWatchTextEditStateEvent event,
    Emitter<TextEditState> emit,
  ) async {
    await emit.forEach(
      notifierChangesStream(context.textEdit)
          .map((_) => context.textEdit.session),
      onData: (session) => switch (session) {
        null => const TextEditClosed(),
        EditTextEditSession(
          :final featureId,
          :final initialContents,
          :final layout,
        ) =>
          EditTextEditOpen(
            featureId: featureId,
            initialContents: initialContents,
            layout: layout,
          ),
        CreateTextEditSession(
          :final worldOrigin,
          :final initialContents,
          :final layout,
        ) =>
          CreateTextEditOpen(
            worldOrigin: worldOrigin,
            initialContents: initialContents,
            layout: layout,
          ),
      },
    );
  }
}
