import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/event.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/state.dart';
import 'package:squiggle_flutter/editor/style_panel/style_presets.dart';
import 'package:squiggle_flutter/models/commands/command.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/feature_id.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';

class StylePanelBloc extends Bloc<StylePanelEvent, StylePanelState> {
  StylePanelBloc({
    required this.documentRepository,
    required this.selectionRepository,
  }) : super(const StylePanelHiddenState()) {
    on<RequestWatchStylePanelStateEvent>(_onRequestWatchStylePanelState);
    on<SetStrokePresetEvent>(_onSetStrokePreset);
    on<ClearStrokeEvent>(_onClearStroke);
    on<SetFillPresetEvent>(_onSetFillPreset);
    on<ClearFillEvent>(_onClearFill);
    on<SetStrokeWidthEvent>(_onSetStrokeWidth);
    on<SetFontSizeEvent>(_onSetFontSize);
  }

  final DocumentRepository documentRepository;
  final SelectionRepository selectionRepository;

  Future<void> _onRequestWatchStylePanelState(
    RequestWatchStylePanelStateEvent event,
    Emitter<StylePanelState> emit,
  ) async {
    emit(_deriveState());

    await Future.wait([
      emit.forEach(
        selectionRepository.selectedFeaturesStream,
        onData: (_) => _deriveState(),
      ),
      emit.forEach(
        documentRepository.changesStream,
        onData: (_) => _deriveState(),
      ),
    ]);
  }

  StylePanelState _deriveState() {
    final selectedFeatureIds = List<FeatureId>.of(
      selectionRepository.selectedFeatures,
    );
    if (selectedFeatureIds.isEmpty) {
      return const StylePanelHiddenState();
    }

    final kinds = selectedFeatureIds
        .map(documentRepository.document.featureById)
        .whereType<Feature>()
        .map((feature) => feature.kind)
        .toList();
    if (kinds.isEmpty) {
      return const StylePanelHiddenState();
    }

    final isStrokeNone = kinds.every((kind) => !kind.hasVisibleStroke);
    final isFillNone = kinds.every((kind) => !kind.hasVisibleFill);

    final strokeColorStates = kinds.map(_strokeColorStateKey).toSet();
    final strokeWidthStates = kinds.map(_strokeWidthStateKey).toSet();
    final fillStates = kinds.map(_fillStateKey).toSet();

    final strokeMixed = strokeColorStates.length > 1;
    final strokeWidthMixed = strokeWidthStates.length > 1;
    final fillMixed = fillStates.length > 1;

    int? activeStrokePresetIndex;
    if (!strokeMixed && !isStrokeNone) {
      activeStrokePresetIndex = strokePresetIndexForColor(
        kinds.first.strokeColor,
      );
    }

    int? activeFillPresetIndex;
    if (!fillMixed && !isFillNone) {
      activeFillPresetIndex = fillPresetIndexForColor(kinds.first.fillColor);
    }

    StrokeWidthPreset? activeStrokeWidth;
    if (!strokeWidthMixed) {
      activeStrokeWidth = StrokeWidthPreset.fromWidth(kinds.first.strokeWidth);
    }

    final textKinds = kinds.whereType<FeatureKindText>().toList();
    final showFontSize = textKinds.isNotEmpty;

    var fontSizeMixed = false;
    FontSizePreset? activeFontSize;
    if (showFontSize) {
      final fontSizeStates = textKinds.map((kind) => kind.fontSize).toSet();
      fontSizeMixed = fontSizeStates.length > 1;
      if (!fontSizeMixed) {
        activeFontSize = FontSizePreset.fromSize(textKinds.first.fontSize);
      }
    }

    return StylePanelShowingState(
      selectedFeatureIds: selectedFeatureIds,
      activeStrokePresetIndex: activeStrokePresetIndex,
      isStrokeNone: isStrokeNone,
      strokeMixed: strokeMixed,
      strokeWidthMixed: strokeWidthMixed,
      activeFillPresetIndex: activeFillPresetIndex,
      isFillNone: isFillNone,
      fillMixed: fillMixed,
      activeStrokeWidth: activeStrokeWidth,
      canClearStroke: !isStrokeNone,
      canClearFill: !isFillNone,
      showFontSize: showFontSize,
      fontSizeMixed: fontSizeMixed,
      activeFontSize: activeFontSize,
    );
  }

  String _strokeColorStateKey(FeatureKind kind) {
    if (!kind.hasVisibleStroke) {
      return 'none';
    }
    return 'stroke:${kind.strokeColor.toARGB32()}';
  }

  String _strokeWidthStateKey(FeatureKind kind) {
    return 'width:${kind.strokeWidth}';
  }

  String _fillStateKey(FeatureKind kind) {
    if (!kind.hasVisibleFill) {
      return 'none';
    }
    return 'fill:${kind.fillColor.toARGB32()}';
  }

  List<FeatureId> _selectedIdsOrEmpty() {
    final current = state;
    if (current is! StylePanelShowingState) {
      return const [];
    }
    return current.selectedFeatureIds;
  }

  void _applyStyleUpdate({
    Color? strokeColor,
    Color? fillColor,
    double? strokeWidth,
    double? fontSize,
  }) {
    final ids = _selectedIdsOrEmpty();
    if (ids.isEmpty) return;

    documentRepository.executeCommand(
      UpdateFeaturesStyleCommand(
        ids: ids,
        strokeColor: strokeColor,
        fillColor: fillColor,
        strokeWidth: strokeWidth,
        fontSize: fontSize,
      ),
    );
  }

  void _onSetStrokePreset(
    SetStrokePresetEvent event,
    Emitter<StylePanelState> emit,
  ) {
    if (state is! StylePanelShowingState) return;
    if (event.index < 0 || event.index >= stylePresets.length) return;

    final preset = stylePresets[event.index];
    _applyStyleUpdate(strokeColor: preset.strokeColor);
  }

  void _onClearStroke(
    ClearStrokeEvent event,
    Emitter<StylePanelState> emit,
  ) {
    final current = state;
    if (current is! StylePanelShowingState || !current.canClearStroke) return;

    _applyStyleUpdate(strokeColor: transparentStrokeColor);
  }

  void _onSetFillPreset(
    SetFillPresetEvent event,
    Emitter<StylePanelState> emit,
  ) {
    if (state is! StylePanelShowingState) return;
    if (event.index < 0 || event.index >= stylePresets.length) return;

    final preset = stylePresets[event.index];
    _applyStyleUpdate(fillColor: preset.fillColor);
  }

  void _onClearFill(
    ClearFillEvent event,
    Emitter<StylePanelState> emit,
  ) {
    final current = state;
    if (current is! StylePanelShowingState || !current.canClearFill) return;

    _applyStyleUpdate(fillColor: transparentFillColor);
  }

  void _onSetStrokeWidth(
    SetStrokeWidthEvent event,
    Emitter<StylePanelState> emit,
  ) {
    if (state is! StylePanelShowingState) return;

    _applyStyleUpdate(strokeWidth: event.preset.width);
  }

  void _onSetFontSize(
    SetFontSizeEvent event,
    Emitter<StylePanelState> emit,
  ) {
    if (state is! StylePanelShowingState) return;

    _applyStyleUpdate(fontSize: event.preset.size);
  }
}
