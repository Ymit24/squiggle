import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/bloc.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/event.dart';
import 'package:squiggle_flutter/editor/text_edit/bloc/state.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/label_layout.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';

const _layout = LabelLayout(
  bounds: Rect.fromLTWH(10, 20, 200, 48),
  fontSize: 24,
  color: Color(0xFFFFFFFF),
  horizontalAlignment: TextHorizontalAlignment.left,
  verticalAlignment: TextVerticalAlignment.top,
);

void main() {
  group('TextEditBloc', () {
    late EditorContext context;

    setUp(() {
      context = EditorContext(
        document: Document.fromFeatures([
          Feature(
            origin: const Offset(0, 0),
            size: const Size(200, 48),
            kind: FeatureKindText(
              'initial text',
              strokeColor: Color(0xFFFFFFFF),
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

      final feature = (context.document.nodes.first as Feature);
      context.startTextEdit(
        EditTextEditSession(
          featureId: feature.id,
          initialContents: 'initial text',
          layout: _layout,
        ),
      );

      final openState = await bloc.stream.firstWhere(
        (state) => state is EditTextEditOpen,
      ) as EditTextEditOpen;

      expect(openState.featureId, feature.id);
      expect(openState.initialContents, 'initial text');
      expect(openState.layout, _layout);
      await bloc.close();
    });

    for (final testCase in <({String name, FeatureKind Function() createKind})>[
      (name: 'text', createKind: () => FeatureKindText('initial text')),
      (
        name: 'rectangle',
        createKind: () => FeatureKindRectangle(label: 'initial text'),
      ),
      (
        name: 'circle',
        createKind: () => FeatureKindCircle(label: 'initial text'),
      ),
    ]) {
      test('TextEditSubmitted updates ${testCase.name} label as one undoable '
          'command', () async {
        context = EditorContext(
          document: Document.fromFeatures([
            Feature(
              origin: Offset.zero,
              size: const Size(200, 48),
              kind: testCase.createKind(),
            ),
          ]),
        );
        final bloc = createBloc();
        bloc.add(const RequestWatchTextEditStateEvent());
        await Future<void>.delayed(Duration.zero);

        final feature = (context.document.nodes.first as Feature);
        final originalSize = feature.size;
        final originalKindData = Map<String, dynamic>.of(
          feature.kind.toDataModel(),
        )..remove('label');
        context.startTextEdit(
          EditTextEditSession(
            featureId: feature.id,
            initialContents: 'initial text',
            layout: _layout,
          ),
        );
        await bloc.stream.firstWhere((state) => state is EditTextEditOpen);

        bloc.add(const TextEditSubmitted('updated text'));
        final closedState = await bloc.stream.firstWhere(
          (state) => state is TextEditClosed,
        );

        expect(closedState, isA<TextEditClosed>());
        expect((feature.kind as LabelCapable).label, 'updated text');
        final updatedSize = feature.size;
        if (feature.kind is! FeatureKindText) {
          expect(
            Map<String, dynamic>.of(feature.kind.toDataModel())
              ..remove('label'),
            originalKindData,
          );
        }

        context.history.undo();
        expect((feature.kind as LabelCapable).label, 'initial text');
        expect(feature.size, originalSize);

        context.history.redo();
        expect((feature.kind as LabelCapable).label, 'updated text');
        expect(feature.size, updatedSize);
        await bloc.close();
      });
    }

    test('editing hides the feature label until the session ends', () {
      final feature = context.document.nodes.first as Feature;

      context.startTextEdit(EditTextEditSession.forFeature(feature));
      expect(feature.hideLabel, isTrue);

      context.endTextEdit();
      expect(feature.hideLabel, isFalse);
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
          layout: _layout,
        ),
      );
      await bloc.stream.firstWhere((state) => state is CreateTextEditOpen);

      expect(context.document.nodes, hasLength(1));

      bloc.add(const TextEditSubmitted('new text'));
      await bloc.stream.firstWhere((state) => state is TextEditClosed);

      expect(context.document.nodes, hasLength(2));
      final created = (context.document.nodes.last as Feature);
      expect(created.origin, origin);
      expect((created.kind as FeatureKindText).label, 'new text');
      expect(created.size.width, defaultNewTextWidth);
      await bloc.close();
    });

    test('outside-click submit creates text without selecting it', () async {
      final bloc = createBloc();
      bloc.add(const RequestWatchTextEditStateEvent());
      await Future<void>.delayed(Duration.zero);

      context.startTextEdit(
        CreateTextEditSession(
          worldOrigin: const Offset(100, 200),
          initialContents: '',
          layout: _layout,
        ),
      );
      await bloc.stream.firstWhere((state) => state is CreateTextEditOpen);

      bloc.add(const TextEditSubmitted('new text', selectCreated: false));
      await bloc.stream.firstWhere((state) => state is TextEditClosed);

      expect(context.document.nodes, hasLength(2));
      expect(context.selection.isEmpty, isTrue);
      await bloc.close();
    });

    test(
      'CreateTextEditSession empty submit leaves document unchanged',
      () async {
        final bloc = createBloc();
        bloc.add(const RequestWatchTextEditStateEvent());
        await Future<void>.delayed(Duration.zero);

        context.startTextEdit(
          CreateTextEditSession(
            worldOrigin: const Offset(100, 200),
            initialContents: '',
            layout: _layout,
          ),
        );
        await bloc.stream.firstWhere((state) => state is CreateTextEditOpen);

        bloc.add(const TextEditSubmitted(''));
        await bloc.stream.firstWhere((state) => state is TextEditClosed);

        expect(context.document.nodes, hasLength(1));
        await bloc.close();
      },
    );
  });
}
