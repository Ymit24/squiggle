import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_commands.dart';
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
  group('commitTextEdit', () {
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

    tearDown(() => context.dispose());

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
      test('updates ${testCase.name} label as one undoable command', () {
        context = EditorContext(
          document: Document.fromFeatures([
            Feature(
              origin: Offset.zero,
              size: const Size(200, 48),
              kind: testCase.createKind(),
            ),
          ]),
        );
        final feature = context.document.nodes.first as Feature;
        final originalSize = feature.size;
        final originalKindData = Map<String, dynamic>.of(
          feature.kind.toDataModel(),
        )..remove('label');
        context.startTextEdit(
          EditTextEditSession(
            feature: feature,
            initialContents: 'initial text',
            layout: _layout,
          ),
        );

        commitTextEdit(context, contents: 'updated text');

        expect(context.textEdit.session, isNull);
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
      });
    }

    test('defaults to the draft typed so far', () {
      final feature = context.document.nodes.first as Feature;
      context.startTextEdit(EditTextEditSession.forFeature(feature));
      context.textEdit.draft = 'from the draft';

      commitTextEdit(context);

      expect((feature.kind as LabelCapable).label, 'from the draft');
    });

    test('does nothing when no edit is open', () {
      commitTextEdit(context, contents: 'ignored');

      expect(context.history.canUndo, isFalse);
    });

    test('editing hides the feature label until the session ends', () {
      final feature = context.document.nodes.first as Feature;

      context.startTextEdit(EditTextEditSession.forFeature(feature));
      expect(feature.hideLabel, isTrue);

      context.endTextEdit();
      expect(feature.hideLabel, isFalse);
    });

    test('starting another session shows the previous label again', () {
      final first = context.document.nodes.first as Feature;
      final second = Feature(
        origin: const Offset(300, 0),
        size: const Size(200, 48),
        kind: FeatureKindText('other'),
      );
      context.history.run('Add', (transaction) => transaction.add(second));

      context.startTextEdit(EditTextEditSession.forFeature(first));
      context.startTextEdit(EditTextEditSession.forFeature(second));

      expect(first.hideLabel, isFalse);
      expect(second.hideLabel, isTrue);
    });

    test('CreateTextEditSession commit adds and selects the feature', () {
      const origin = Offset(100, 200);
      context.startTextEdit(
        CreateTextEditSession(draft: newTextFeatureAt(origin, '')),
      );
      expect(context.document.nodes, hasLength(1));

      commitTextEdit(context, contents: 'new text');

      expect(context.document.nodes, hasLength(2));
      final created = context.document.nodes.last as Feature;
      expect(created.origin, origin);
      expect((created.kind as FeatureKindText).label, 'new text');
      expect((created.kind as FeatureKindText).sizing, TextSizing.auto);
      expect(context.selection.selectedNodeIds, [created.id]);
    });

    test('dragged CreateTextEditSession commits fixed-width text', () {
      context.startTextEdit(
        CreateTextEditSession(
          draft: newTextFeatureAt(const Offset(10, 20), '', fixedWidth: 90),
        ),
      );

      commitTextEdit(context, contents: 'wrap me please, I am long');

      final created = context.document.nodes.last as Feature;
      expect((created.kind as FeatureKindText).sizing, TextSizing.fixedWidth);
      expect(created.origin, const Offset(10, 20));
      expect(created.size.width, 90);
      expect(created.size.height, greaterThan(40));
    });

    test('a brush cannot override the sizing the gesture chose', () {
      context.brushes.active.values['sizing'] = 'fixedWidth';

      context.startCreateText(const Offset(5, 5));
      commitTextEdit(context, contents: 'click made');
      context.startCreateText(const Offset(5, 50), fixedWidth: 120);
      commitTextEdit(context, contents: 'drag made');

      final kinds = context.document.nodes
          .skip(1)
          .map((node) => (node as Feature).kind as FeatureKindText)
          .toList();
      expect(kinds.map((kind) => kind.sizing), [
        TextSizing.auto,
        TextSizing.fixedWidth,
      ]);
    });

    test('a near-zero dragged width is widened to the minimum', () {
      context.startCreateText(const Offset(5, 5), fixedWidth: 0.3);
      commitTextEdit(context, contents: 'x');

      final created = context.document.nodes.last as Feature;
      expect(created.width, (created.kind as FeatureKindText).fontSize);
    });

    test('outside-click commit creates text without selecting it', () {
      context.startTextEdit(
        CreateTextEditSession(
          draft: newTextFeatureAt(const Offset(100, 200), ''),
        ),
      );

      commitTextEdit(context, contents: 'new text', selectCreated: false);

      expect(context.document.nodes, hasLength(2));
      expect(context.selection.isEmpty, isTrue);
    });

    test('empty create commit leaves the document unchanged', () {
      context.startTextEdit(
        CreateTextEditSession(
          draft: newTextFeatureAt(const Offset(100, 200), ''),
        ),
      );

      commitTextEdit(context, contents: '');

      expect(context.document.nodes, hasLength(1));
      expect(context.textEdit.session, isNull);
    });
  });
}
