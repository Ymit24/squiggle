import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/text_edit_model.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';

import 'select_tool_test_harness.dart';

void main() {
  group('IdleInteractionState', () {
    late SelectToolTestHarness harness;

    setUp(() => harness = SelectToolTestHarness());

    test('double-clicking text starts a text edit session', () async {
      harness.context = _textContext();
      final feature = harness.context.document.nodes.first;
      final sessions = <TextEditSession>[];
      final subscription = notifierChangesStream(harness.context.textEdit)
          .map((_) => harness.context.textEdit.session)
          .where((session) => session != null)
          .cast<TextEditSession>()
          .listen(sessions.add);

      harness.doubleClick(const Offset(50, 24));
      await Future<void>.delayed(Duration.zero);

      expect(harness.context.selection.selectedNodeIds, [feature.id]);
      expect(sessions, hasLength(1));
      final session = sessions.single as EditTextEditSession;
      expect(session.featureId, feature.id);
      expect(session.initialContents, 'hello world');
      expect(
        session.canvasLocalBounds,
        harness.camera.worldToScreenBounds(feature.localBounds()),
      );
      await subscription.cancel();
    });

    test(
      'double-clicking a non-text node does not start text editing',
      () async {
        final sessions = <TextEditSession>[];
        final subscription = notifierChangesStream(harness.context.textEdit)
            .map((_) => harness.context.textEdit.session)
            .where((session) => session != null)
            .cast<TextEditSession>()
            .listen(sessions.add);

        harness.doubleClick(const Offset(50, 50));
        await Future<void>.delayed(Duration.zero);

        expect(sessions, isEmpty);
        await subscription.cancel();
      },
    );

    test('double-clicking the canvas starts a create text edit session', () {
      const click = Offset(150, 75);
      harness.camera
        ..location = const Offset(25, 15)
        ..zoom = 2;

      harness.doubleClick(click);

      final session =
          harness.context.textEdit.session as CreateTextEditSession;
      expect(session.worldOrigin, click);
      expect(session.initialContents, isEmpty);
      expect(
        session.canvasLocalBounds,
        harness.camera.worldToScreenBounds(newTextBoundsAt(click)),
      );
    });

    for (final key in [
      LogicalKeyboardKey.delete,
      LogicalKeyboardKey.backspace,
    ]) {
      test('${key.keyLabel} deletes selected nodes as one undo entry', () {
        final feature = harness.context.document.nodes.first;
        harness.context.selection.selectNode(feature.id);

        expect(harness.keyDown(key), isTrue);
        expect(harness.context.document.featureById(feature.id), isNull);
        expect(harness.context.selection.selectedNodeIds, isEmpty);

        harness.context.history.undo();
        expect(harness.context.document.featureById(feature.id), isNotNull);
      });
    }

    test('ignores unrelated keys', () {
      harness.context.selection.selectNode(
        harness.context.document.nodes.first.id,
      );

      expect(harness.keyDown(LogicalKeyboardKey.enter), isFalse);
      expect(harness.context.document.nodes, hasLength(2));
    });
  });
}

EditorContext _textContext() => EditorContext(
  document: Document.fromFeatures([
    Feature(
      origin: Offset.zero,
      size: const Size(200, 48),
      kind: const FeatureKindText('hello world', fillColor: Color(0xFFFFFFFF)),
    ),
  ]),
);
