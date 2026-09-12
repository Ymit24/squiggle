import 'package:flutter_test/flutter_test.dart';

import 'select_tool_test_harness.dart';

void main() {
  group('ClickCanvasState', () {
    late SelectToolTestHarness harness;

    setUp(() {
      harness = SelectToolTestHarness();
      harness.context.selection.selectNode(
        harness.context.document.nodes.first.id,
      );
    });

    test('clears selection on an empty click', () {
      harness.click(const Offset(500, 500));

      expect(harness.context.selection.selectedNodeIds, isEmpty);
    });

    test('shift-click on empty canvas preserves selection', () {
      final selectedId = harness.context.document.nodes.first.id;

      harness.click(const Offset(500, 500), shift: true);

      expect(harness.context.selection.selectedNodeIds, [selectedId]);
    });
  });
}
