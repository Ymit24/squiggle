import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/bloc/state.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/selection.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  final Document document;
  final SelectionRepository selectionRepository;

  EditorBloc({required this.document, required this.selectionRepository})
    : super(EditorState.empty(document)) {
    on<SelectFeatureEvent>(_onSelectFeature);
    on<DeselectFeatureEvent>(_onDeselectFeature);
  }

  void _onSelectFeature(SelectFeatureEvent event, Emitter<EditorState> emit) {
    selectionRepository.selectFeature(event.featureId);
    emit(
      state.copyWith(selectedFeatures: selectionRepository.selectedFeatures),
    );
  }

  void _onDeselectFeature(
    DeselectFeatureEvent event,
    Emitter<EditorState> emit,
  ) {
    selectionRepository.deselectFeature(event.featureId);
    emit(
      state.copyWith(selectedFeatures: selectionRepository.selectedFeatures),
    );
  }
}
