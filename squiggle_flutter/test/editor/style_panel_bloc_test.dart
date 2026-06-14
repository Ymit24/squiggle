import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/event.dart';
import 'package:squiggle_flutter/editor/style_panel/bloc/state.dart';
import 'package:squiggle_flutter/editor/style_panel/style_presets.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';

void main() {
  group('StylePanelBloc', () {
    late DocumentRepository documentRepository;
    late SelectionRepository selectionRepository;

    setUp(() {
      documentRepository = DocumentRepository(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(100, 100),
            kind: FeatureKindRectangle(
              strokeColor: stylePresets[1].strokeColor,
              fillColor: stylePresets[1].fillColor,
              strokeWidth: StrokeWidthPreset.medium.width,
            ),
          ),
          Feature(
            origin: const Offset(120, 0),
            size: const Size(100, 100),
            kind: FeatureKindCircle(
              strokeColor: stylePresets[0].strokeColor,
              fillColor: stylePresets[0].fillColor,
              strokeWidth: StrokeWidthPreset.medium.width,
            ),
          ),
          Feature(
            origin: const Offset(240, 0),
            size: const Size(200, 48),
            kind: const FeatureKindText(
              'hello',
              fillColor: Color(0xFFFFFFFF),
            ),
          ),
        ]),
      );
      selectionRepository = SelectionRepository();
    });

    tearDown(() {
      documentRepository.dispose();
    });

    StylePanelBloc createBloc() => StylePanelBloc(
      documentRepository: documentRepository,
      selectionRepository: selectionRepository,
    );

    test('emits StylePanelHiddenState when selection is empty', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      expect(bloc.state, isA<StylePanelHiddenState>());
      await bloc.close();
    });

    test('emits StylePanelShowingState when selection is non-empty', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      selectionRepository.selectFeature(
        documentRepository.document.features.first.id,
      );
      final showingState = await bloc.stream.firstWhere(
        (state) => state is StylePanelShowingState,
      );

      expect(showingState, isA<StylePanelShowingState>());
      expect(
        (showingState as StylePanelShowingState).selectedFeatureIds,
        hasLength(1),
      );
      await bloc.close();
    });

    test('highlights active preset when all selected share a preset', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      selectionRepository.selectFeature(
        documentRepository.document.features.first.id,
      );
      final showingState = await bloc.stream.firstWhere(
        (state) => state is StylePanelShowingState,
      ) as StylePanelShowingState;

      expect(showingState.activeStrokePresetIndex, 1);
      expect(showingState.activeFillPresetIndex, 1);
      expect(showingState.activeStrokeWidth, StrokeWidthPreset.medium);
      expect(showingState.strokeMixed, isFalse);
      expect(showingState.fillMixed, isFalse);
      expect(showingState.showFontSize, isFalse);
      await bloc.close();
    });

    test('reports mixed state when selected features disagree', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      for (final feature in documentRepository.document.features) {
        selectionRepository.selectFeature(feature.id);
      }
      final showingState = await bloc.stream.firstWhere(
        (state) =>
            state is StylePanelShowingState &&
            (state as StylePanelShowingState).strokeMixed,
      ) as StylePanelShowingState;

      expect(showingState.activeStrokePresetIndex, isNull);
      expect(showingState.activeFillPresetIndex, isNull);
      expect(showingState.strokeMixed, isTrue);
      expect(showingState.fillMixed, isTrue);
      await bloc.close();
    });

    test('canClearStroke and canClearFill when one style is none', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      final featureId = documentRepository.document.features.first.id;
      selectionRepository.selectFeature(featureId);

      documentRepository.executeCommand(
        UpdateFeaturesStyleCommand(
          ids: [featureId],
          fillColor: transparentFillColor,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      final showingState = bloc.state as StylePanelShowingState;
      expect(showingState.isFillNone, isTrue);
      expect(showingState.canClearStroke, isTrue);
      expect(showingState.canClearFill, isFalse);
      await bloc.close();
    });

    test('ClearStrokeEvent clears stroke color but preserves width', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      final featureId = documentRepository.document.features.first.id;
      selectionRepository.selectFeature(featureId);
      await bloc.stream.firstWhere((state) => state is StylePanelShowingState);

      bloc.add(const ClearStrokeEvent());
      await Future<void>.delayed(Duration.zero);

      final kind = documentRepository.document.features.first.kind;
      expect(kind.hasVisibleStroke, isFalse);
      expect(kind.strokeWidth, StrokeWidthPreset.medium.width);
      await bloc.close();
    });

    test('ClearStrokeEvent works when fill is already none', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      final featureId = documentRepository.document.features.first.id;
      selectionRepository.selectFeature(featureId);
      await bloc.stream.firstWhere((state) => state is StylePanelShowingState);

      documentRepository.executeCommand(
        UpdateFeaturesStyleCommand(
          ids: [featureId],
          fillColor: transparentFillColor,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      bloc.add(const ClearStrokeEvent());
      await Future<void>.delayed(Duration.zero);

      final kind = documentRepository.document.features.first.kind;
      expect(kind.hasVisibleStroke, isFalse);
      expect(kind.hasVisibleFill, isFalse);
      expect(kind.strokeWidth, StrokeWidthPreset.medium.width);
      await bloc.close();
    });

    test('style events no-op in StylePanelHiddenState', () async {
      final bloc = createBloc();
      bloc.add(const SetStrokePresetEvent(0));
      await Future<void>.delayed(Duration.zero);

      expect(documentRepository.document.features.first.kind.strokeColor,
          stylePresets[1].strokeColor);
      await bloc.close();
    });

    test('SetStrokePresetEvent updates selected features', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      selectionRepository.selectFeature(
        documentRepository.document.features.first.id,
      );
      await bloc.stream.firstWhere((state) => state is StylePanelShowingState);

      bloc.add(const SetStrokePresetEvent(0));
      await Future<void>.delayed(Duration.zero);

      expect(
        documentRepository.document.features.first.kind.strokeColor,
        stylePresets[0].strokeColor,
      );
      await bloc.close();
    });

    test('shows font size controls when a text feature is selected', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      final textFeature = documentRepository.document.features.last;
      selectionRepository.selectFeature(textFeature.id);
      final showingState = await bloc.stream.firstWhere(
        (state) => state is StylePanelShowingState,
      ) as StylePanelShowingState;

      expect(showingState.showFontSize, isTrue);
      expect(showingState.activeFontSize, FontSizePreset.medium);
      expect(showingState.fontSizeMixed, isFalse);
      await bloc.close();
    });

    test('hides font size controls when only non-text features are selected',
        () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      selectionRepository.selectFeature(
        documentRepository.document.features.first.id,
      );
      final showingState = await bloc.stream.firstWhere(
        (state) => state is StylePanelShowingState,
      ) as StylePanelShowingState;

      expect(showingState.showFontSize, isFalse);
      await bloc.close();
    });

    test('shows font size controls for mixed text and shape selection', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      selectionRepository.selectFeature(
        documentRepository.document.features.first.id,
      );
      selectionRepository.selectFeature(
        documentRepository.document.features.last.id,
      );
      final showingState = await bloc.stream.firstWhere(
        (state) =>
            state is StylePanelShowingState &&
            (state as StylePanelShowingState).showFontSize,
      ) as StylePanelShowingState;

      expect(showingState.showFontSize, isTrue);
      await bloc.close();
    });

    test('SetFontSizeEvent updates only selected text features', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchStylePanelStateEvent());
      await bloc.stream.first;

      final rect = documentRepository.document.features.first;
      final text = documentRepository.document.features.last;
      selectionRepository.selectFeature(rect.id);
      selectionRepository.selectFeature(text.id);
      await bloc.stream.firstWhere(
        (state) =>
            state is StylePanelShowingState &&
            (state as StylePanelShowingState).showFontSize,
      );

      bloc.add(const SetFontSizeEvent(FontSizePreset.large));
      await Future<void>.delayed(Duration.zero);

      expect(rect.kind, isA<FeatureKindRectangle>());
      final textKind = text.kind as FeatureKindText;
      expect(textKind.fontSize, FontSizePreset.large.size);
      await bloc.close();
    });

  });
}
