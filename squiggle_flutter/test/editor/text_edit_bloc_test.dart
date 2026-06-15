import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/text_edit_repository.dart';

void main() {
  group('TextEditBloc', () {
    late DocumentRepository documentRepository;
    late TextEditRepository textEditRepository;

    setUp(() {
      documentRepository = DocumentRepository(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(200, 48),
            kind: const FeatureKindText(
              'initial text',
              fillColor: Color(0xFFFFFFFF),
            ),
          ),
        ]),
      );
      textEditRepository = TextEditRepository();
    });

    tearDown(() {
      textEditRepository.dispose();
      documentRepository.dispose();
    });

    TextEditBloc createBloc() => TextEditBloc(
      documentRepository: documentRepository,
      textEditRepository: textEditRepository,
    );

    test('beginEdit emits TextEditOpen', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchTextEditStateEvent());
      await Future<void>.delayed(Duration.zero);

      final feature = documentRepository.document.features.first;
      const bounds = Rect.fromLTWH(10, 20, 200, 48);
      textEditRepository.beginEdit(
        TextEditSession(
          featureId: feature.id,
          initialContents: 'initial text',
          canvasLocalBounds: bounds,
        ),
      );

      final openState = await bloc.stream.firstWhere(
        (state) => state is TextEditOpen,
      ) as TextEditOpen;

      expect(openState.featureId, feature.id);
      expect(openState.initialContents, 'initial text');
      expect(openState.canvasLocalBounds, bounds);
      await bloc.close();
    });

    test('TextEditSubmitted applies command and emits TextEditClosed', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchTextEditStateEvent());
      await Future<void>.delayed(Duration.zero);

      final feature = documentRepository.document.features.first;
      textEditRepository.beginEdit(
        TextEditSession(
          featureId: feature.id,
          initialContents: 'initial text',
          canvasLocalBounds: const Rect.fromLTWH(0, 0, 200, 48),
        ),
      );
      await bloc.stream.firstWhere((state) => state is TextEditOpen);

      bloc.add(const TextEditSubmitted('updated text'));
      final closedState = await bloc.stream.firstWhere(
        (state) => state is TextEditClosed,
      );

      expect(closedState, isA<TextEditClosed>());
      expect(
        (documentRepository.document.features.first.kind as FeatureKindText)
            .contents,
        'updated text',
      );
      await bloc.close();
    });

    test('TextEditCancelled emits TextEditClosed without command', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchTextEditStateEvent());
      await Future<void>.delayed(Duration.zero);

      final feature = documentRepository.document.features.first;
      textEditRepository.beginEdit(
        TextEditSession(
          featureId: feature.id,
          initialContents: 'initial text',
          canvasLocalBounds: const Rect.fromLTWH(0, 0, 200, 48),
        ),
      );
      await bloc.stream.firstWhere((state) => state is TextEditOpen);

      bloc.add(const TextEditCancelled());
      final closedState = await bloc.stream.firstWhere(
        (state) => state is TextEditClosed,
      );

      expect(closedState, isA<TextEditClosed>());
      expect(
        (documentRepository.document.features.first.kind as FeatureKindText)
            .contents,
        'initial text',
      );
      await bloc.close();
    });
  });
}
