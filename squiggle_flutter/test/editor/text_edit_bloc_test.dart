import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';

void main() {
  group('TextEditBloc', () {
    late EditorContext context;

    setUp(() {
      context = EditorContext(
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
    });

    TextEditBloc createBloc() => TextEditBloc(context: context);

    test('beginEdit emits EditTextEditOpen', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchTextEditStateEvent());
      await Future<void>.delayed(Duration.zero);

      final feature = context.document.features.first;
      const bounds = Rect.fromLTWH(10, 20, 200, 48);
      context.startTextEdit(
        EditTextEditSession(
          featureId: feature.id,
          initialContents: 'initial text',
          canvasLocalBounds: bounds,
        ),
      );

      final openState = await bloc.stream.firstWhere(
        (state) => state is EditTextEditOpen,
      ) as EditTextEditOpen;

      expect(openState.featureId, feature.id);
      expect(openState.initialContents, 'initial text');
      expect(openState.canvasLocalBounds, bounds);
      await bloc.close();
    });

    test('TextEditSubmitted applies command and emits TextEditClosed', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchTextEditStateEvent());
      await Future<void>.delayed(Duration.zero);

      final feature = context.document.features.first;
      context.startTextEdit(
        EditTextEditSession(
          featureId: feature.id,
          initialContents: 'initial text',
          canvasLocalBounds: const Rect.fromLTWH(0, 0, 200, 48),
        ),
      );
      await bloc.stream.firstWhere((state) => state is EditTextEditOpen);

      bloc.add(const TextEditSubmitted('updated text'));
      final closedState = await bloc.stream.firstWhere(
        (state) => state is TextEditClosed,
      );

      expect(closedState, isA<TextEditClosed>());
      expect(
        (context.document.features.first.kind as FeatureKindText).contents,
        'updated text',
      );
      await bloc.close();
    });

    test('TextEditCancelled emits TextEditClosed without command', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchTextEditStateEvent());
      await Future<void>.delayed(Duration.zero);

      final feature = context.document.features.first;
      context.startTextEdit(
        EditTextEditSession(
          featureId: feature.id,
          initialContents: 'initial text',
          canvasLocalBounds: const Rect.fromLTWH(0, 0, 200, 48),
        ),
      );
      await bloc.stream.firstWhere((state) => state is EditTextEditOpen);

      bloc.add(const TextEditCancelled());
      final closedState = await bloc.stream.firstWhere(
        (state) => state is TextEditClosed,
      );

      expect(closedState, isA<TextEditClosed>());
      expect(
        (context.document.features.first.kind as FeatureKindText).contents,
        'initial text',
      );
      await bloc.close();
    });

    test('CreateTextEditSession submit adds feature', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchTextEditStateEvent());
      await Future<void>.delayed(Duration.zero);

      const origin = Offset(100, 200);
      context.startTextEdit(
        CreateTextEditSession(
          worldOrigin: origin,
          initialContents: '',
          canvasLocalBounds: const Rect.fromLTWH(0, 0, 200, 24),
        ),
      );
      await bloc.stream.firstWhere((state) => state is CreateTextEditOpen);

      expect(context.document.features, hasLength(1));

      bloc.add(const TextEditSubmitted('new text'));
      await bloc.stream.firstWhere((state) => state is TextEditClosed);

      expect(context.document.features, hasLength(2));
      final created = context.document.features.last;
      expect(created.origin, origin);
      expect((created.kind as FeatureKindText).contents, 'new text');
      expect(created.size.width, defaultNewTextWidth);
      await bloc.close();
    });

    test('CreateTextEditSession cancel leaves document unchanged', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchTextEditStateEvent());
      await Future<void>.delayed(Duration.zero);

      context.startTextEdit(
        CreateTextEditSession(
          worldOrigin: const Offset(100, 200),
          initialContents: '',
          canvasLocalBounds: const Rect.fromLTWH(0, 0, 200, 24),
        ),
      );
      await bloc.stream.firstWhere((state) => state is CreateTextEditOpen);

      bloc.add(const TextEditCancelled());
      await bloc.stream.firstWhere((state) => state is TextEditClosed);

      expect(context.document.features, hasLength(1));
      await bloc.close();
    });

    test('CreateTextEditSession empty submit leaves document unchanged', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchTextEditStateEvent());
      await Future<void>.delayed(Duration.zero);

      context.startTextEdit(
        CreateTextEditSession(
          worldOrigin: const Offset(100, 200),
          initialContents: '',
          canvasLocalBounds: const Rect.fromLTWH(0, 0, 200, 24),
        ),
      );
      await bloc.stream.firstWhere((state) => state is CreateTextEditOpen);

      bloc.add(const TextEditSubmitted(''));
      await bloc.stream.firstWhere((state) => state is TextEditClosed);

      expect(context.document.features, hasLength(1));
      await bloc.close();
    });
  });
}
