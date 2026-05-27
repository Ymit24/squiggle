import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/editor/bloc/state.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/repositories/selection.dart';

class EditorBloc extends Bloc<EditorEvent, EditorState> {
  EditorBloc({required this.document, required this.selectionRepository})
    : super(EditorState.empty(document)) {
    on<PointerDownAtWorldEvent>(_onPointerDownAtWorld);
    on<RequestWatchSelectedFeaturesEvent>(_onRequestWatchSelectedFeatures);
  }

  final Document document;
  final SelectionRepository selectionRepository;

  Future<void> _onRequestWatchSelectedFeatures(
    RequestWatchSelectedFeaturesEvent event,
    Emitter<EditorState> emit,
  ) async {
    emit(
      state.copyWith(
        selectedFeatures: List.of(selectionRepository.selectedFeatures),
      ),
    );
    return emit.forEach(
      selectionRepository.selectedFeaturesStream,
      onData: (selectedFeatures) =>
          state.copyWith(selectedFeatures: List.of(selectedFeatures)),
    );
  }

  Future<void> _onPointerDownAtWorld(
    PointerDownAtWorldEvent event,
    Emitter<EditorState> emit,
  ) async {
    final feature = document.featureAtPoint(event.worldPosition);

    if (feature != null) {
      if (event.isShiftPressed) {
        if (selectionRepository.isFeatureSelected(feature.id)) {
          selectionRepository.deselectFeature(feature.id);
        } else {
          selectionRepository.selectFeature(feature.id);
        }
      } else {
        selectionRepository.clearSelection();
        selectionRepository.selectFeature(feature.id);
      }
    } else if (!event.isShiftPressed) {
      selectionRepository.clearSelection();
    }
  }
}
