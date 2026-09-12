import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';

class TextEditBloc extends Bloc<TextEditEvent, TextEditState> {
  TextEditBloc({required this.context}) : super(const TextEditClosed()) {
    on<RequestWatchTextEditStateEvent>(_onRequestWatchTextEditState);
    on<TextEditSubmitted>(_onTextEditSubmitted);
    on<TextEditCancelled>(_onTextEditCancelled);
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
        _updateText(featureId, event.contents);
      case CreateTextEditOpen(:final worldOrigin):
        if (event.contents.isNotEmpty) {
          context.history.run('Create text', (transaction) {
            transaction.add(newTextFeatureAt(worldOrigin, event.contents));
          });
        }
    }
    context.endTextEdit();
    emit(const TextEditClosed());
  }

  void _onTextEditCancelled(
    TextEditCancelled event,
    Emitter<TextEditState> emit,
  ) {
    context.endTextEdit();
    emit(const TextEditClosed());
  }

  void _updateText(NodeId id, String contents) {
    final feature = context.document.featureById(id);
    if (feature == null) return;
    final textKind = feature.kind;
    if (textKind is! FeatureKindWithLabel) return;
    final labelKind = textKind as FeatureKindWithLabel;

    context.history.run('Edit text', (transaction) {
      transaction.watch([feature]);
      final bounds = feature.localBounds();
      final newKind = FeatureKindText(
        contents,
        fontSize: labelKind.fontSize,
        horizontalAlignment: labelKind.horizontalAlignment,
        verticalAlignment: labelKind.verticalAlignment,
        strokeColor: labelKind.strokeColor,
        fillColor: labelKind.fillColor,
        strokeWidth: labelKind.strokeWidth,
      ).fittedToBounds(width: bounds.width, height: bounds.height);
      feature.setKind(newKind);
    }, container: feature.parent);
  }
}
