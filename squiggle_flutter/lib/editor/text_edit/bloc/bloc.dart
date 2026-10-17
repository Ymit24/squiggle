import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';

class TextEditBloc extends Bloc<TextEditEvent, TextEditState> {
  TextEditBloc({required this.context}) : super(const TextEditClosed()) {
    on<RequestWatchTextEditStateEvent>(_onRequestWatchTextEditState);
    on<TextEditSubmitted>(_onTextEditSubmitted);
  }

  final EditorContext context;

  Future<void> _onRequestWatchTextEditState(
    RequestWatchTextEditStateEvent event,
    Emitter<TextEditState> emit,
  ) async {
    await emit.forEach(
      notifierChangesStream(context.textEdit)
          .map((_) => context.textEdit.session)
          .where((session) => session != null)
          .cast<TextEditSession>(),
      onData: (session) => switch (session) {
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

  void _onTextEditSubmitted(
    TextEditSubmitted event,
    Emitter<TextEditState> emit,
  ) {
    final current = state;
    if (current is! TextEditOpen) return;

    switch (current) {
      case EditTextEditOpen(:final featureId):
        _updateText(featureId, event.contents);
      case CreateTextEditOpen(:final worldOrigin):
        if (event.contents.isNotEmpty) {
          final feature = newTextFeatureAt(
            worldOrigin,
            event.contents,
            configureKind: context.brushes.active.applyTo,
          );
          context.history.run('Create text', (transaction) {
            transaction.add(feature);
          });
          if (event.selectCreated) context.selectCreatedFeature(feature);
        }
    }
    context.endTextEdit();
    emit(const TextEditClosed());
  }

  void _updateText(NodeId id, String contents) {
    final feature = context.document.featureById(id);
    if (feature == null) return;
    if (feature.kind is! LabelCapable) return;
    final labelCapability = feature.kind as LabelCapable;
    context.history.run('Edit text', (transaction) {
      transaction.watch([feature]);
      labelCapability.setLabel(feature, contents);
    }, container: feature.parent);
  }
}
