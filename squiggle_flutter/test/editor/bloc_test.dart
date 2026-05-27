import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/bloc/event.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/selection.dart';

void main() {
  group('EditorBloc pointer selection', () {
    late Document document;
    late SelectionRepository selectionRepository;

    setUp(() {
      document = Document.fromFeatures([
        Feature.newRectangle(const Offset(0, 0), const Size(100, 100)),
        Feature.newRectangle(const Offset(200, 0), const Size(100, 100)),
      ]);
      selectionRepository = SelectionRepository();
    });

    Future<void> dispatch(EditorBloc bloc, PointerDownAtWorldEvent event) async {
      bloc.add(event);
      await bloc.stream.first;
    }

    test('selects feature on click', () async {
      final bloc = EditorBloc(
        document: document,
        selectionRepository: selectionRepository,
      );
      await dispatch(
        bloc,
        const PointerDownAtWorldEvent(
          worldPosition: Offset(50, 50),
          isShiftPressed: false,
        ),
      );

      expect(bloc.state.selectedFeatures.length, 1);
      expect(
        bloc.state.selectedFeatures.single,
        document.features.first.id,
      );
      await bloc.close();
    });

    test('clears selection on empty click', () async {
      selectionRepository.selectFeature(document.features.first.id);
      final bloc = EditorBloc(
        document: document,
        selectionRepository: selectionRepository,
      );
      await dispatch(
        bloc,
        const PointerDownAtWorldEvent(
          worldPosition: Offset(500, 500),
          isShiftPressed: false,
        ),
      );

      expect(bloc.state.selectedFeatures, isEmpty);
      expect(selectionRepository.selectedFeatures, isEmpty);
      await bloc.close();
    });

    test('shift-click adds and removes from selection', () async {
      final bloc = EditorBloc(
        document: document,
        selectionRepository: selectionRepository,
      );

      await dispatch(
        bloc,
        const PointerDownAtWorldEvent(
          worldPosition: Offset(50, 50),
          isShiftPressed: false,
        ),
      );
      await dispatch(
        bloc,
        const PointerDownAtWorldEvent(
          worldPosition: Offset(250, 50),
          isShiftPressed: true,
        ),
      );
      await dispatch(
        bloc,
        const PointerDownAtWorldEvent(
          worldPosition: Offset(50, 50),
          isShiftPressed: true,
        ),
      );

      expect(bloc.state.selectedFeatures.length, 1);
      expect(
        bloc.state.selectedFeatures.single,
        document.features[1].id,
      );
      await bloc.close();
    });

    test('shift-click on empty preserves selection', () async {
      selectionRepository.selectFeature(document.features.first.id);
      final bloc = EditorBloc(
        document: document,
        selectionRepository: selectionRepository,
      );
      await dispatch(
        bloc,
        const PointerDownAtWorldEvent(
          worldPosition: Offset(500, 500),
          isShiftPressed: true,
        ),
      );

      expect(bloc.state.selectedFeatures.length, 1);
      expect(
        bloc.state.selectedFeatures.single,
        document.features.first.id,
      );
      await bloc.close();
    });
  });
}
