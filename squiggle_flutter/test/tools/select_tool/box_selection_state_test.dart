import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/bloc/notifier_stream.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

import 'select_tool_test_harness.dart';

void main() {
  group('BoxSelectionState', () {
    late SelectToolTestHarness harness;

    setUp(() => harness = SelectToolTestHarness());

    test('selects nodes intersecting the marquee', () {
      harness.pointerDown(const Offset(-20, -20));
      harness.pointerMove(const Offset(120, 120));
      harness.pointerUp(const Offset(120, 120));

      expect(harness.context.selection.selectedNodes, [
        harness.context.document.nodes.first.id,
      ]);
    });

    test('updates selection as the marquee changes', () {
      harness.pointerDown(const Offset(-20, -20));
      harness.pointerMove(const Offset(320, 120));
      expect(harness.context.selection.selectedNodes, hasLength(2));

      harness.pointerMove(const Offset(120, 120));

      expect(harness.context.selection.selectedNodes, [
        harness.context.document.nodes.first.id,
      ]);
    });

    test('shift-marquee adds to the existing selection', () {
      final features = harness.context.document.nodes;
      harness.context.selection.selectNode(features.first.id);

      harness.pointerDown(const Offset(180, -20), shift: true);
      harness.pointerMove(const Offset(320, 120), shift: true);
      harness.pointerUp(const Offset(320, 120), shift: true);

      expect(harness.context.selection.selectedNodes, [
        features.first.id,
        features.last.id,
      ]);
    });

    test('notifies the tool while marquee selecting', () async {
      final repaints = <void>[];
      final subscription = notifierChangesStream(
        harness.context.tool,
      ).listen((_) => repaints.add(null));

      harness.pointerDown(const Offset(500, 500));
      harness.pointerMove(const Offset(600, 600));
      await Future<void>.delayed(Duration.zero);

      expect(repaints, isNotEmpty);
      expect(harness.context.tool.activeTool, isA<SelectTool>());
      await subscription.cancel();
    });
  });
}
