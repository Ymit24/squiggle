import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

import 'select_tool_test_harness.dart';

void main() {
  group('TranslateState', () {
    late SelectToolTestHarness harness;

    setUp(() => harness = SelectToolTestHarness());

    test('moves the selection relative to the node that was dragged', () {
      harness.context = EditorContext(
        document: Document.fromFeatures([
          for (final x in [0.0, 100.0, 200.0])
            Feature(
              origin: Offset(x, 0),
              size: const Size(50, 50),
              kind: const FeatureKindRectangle(),
            ),
        ]),
      );
      final features = harness.context.document.nodes;
      for (final point in const [
        Offset(25, 25),
        Offset(125, 25),
        Offset(225, 25),
      ]) {
        harness.click(point, shift: point.dx > 25);
      }

      harness.pointerDown(const Offset(25, 25));
      harness.pointerMove(const Offset(35, 35));

      expect(features.map((feature) => feature.origin), [
        const Offset(10, 10),
        const Offset(110, 10),
        const Offset(210, 10),
      ]);
    });

    test('notifies the editor context when moving nodes', () async {
      harness.pointerDown(const Offset(50, 50));
      final changes = <void>[];
      final subscription = notifierChangesStream(
        harness.context,
      ).listen((_) => changes.add(null));

      harness.pointerMove(const Offset(60, 60));
      await Future<void>.delayed(Duration.zero);

      expect(changes, isNotEmpty);
      await subscription.cancel();
    });

    test('commits one undo entry for a drag', () {
      final feature = harness.context.document.nodes.first;

      harness.pointerDown(const Offset(50, 50));
      harness.pointerMove(const Offset(60, 60));
      harness.pointerMove(const Offset(70, 70));
      harness.pointerMove(const Offset(80, 80));

      expect(feature.origin, const Offset(30, 30));
      expect(harness.context.history.canUndo, isFalse);

      harness.pointerUp(const Offset(80, 80));
      expect(harness.context.history.canUndo, isTrue);

      harness.context.history.undo();
      expect(feature.origin, Offset.zero);
    });

    test('commits one undo entry for a multi-node drag', () {
      final features = harness.context.document.nodes;
      harness.context.selection.setSelection(
        features.map((feature) => feature.id),
      );

      harness.pointerDown(const Offset(50, 50));
      harness.pointerMove(const Offset(70, 70));
      harness.pointerUp(const Offset(70, 70));

      expect(features[0].origin, const Offset(20, 20));
      expect(features[1].origin, const Offset(220, 20));

      harness.context.history.undo();
      expect(features[0].origin, Offset.zero);
      expect(features[1].origin, const Offset(200, 0));
    });

    test('shift-drag constrains movement to the dominant axis', () {
      harness.pointerDown(const Offset(50, 50));
      harness.pointerMove(const Offset(80, 55), shift: true);

      expect(harness.context.document.nodes.first.origin, const Offset(30, 0));
    });

    test('escape cancels movement without recording history', () {
      final feature = harness.context.document.nodes.first;
      harness.pointerDown(const Offset(50, 50));
      harness.pointerMove(const Offset(70, 80));

      expect(harness.keyDown(LogicalKeyboardKey.escape), isTrue);
      harness.pointerUp(const Offset(70, 80));

      expect(feature.origin, Offset.zero);
      expect(harness.context.history.isActive, isFalse);
      expect(harness.context.history.canUndo, isFalse);
    });
  });
}
