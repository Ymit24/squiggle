import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/tools/select_tool/select_tool.dart';

import 'select_tool/select_tool_test_harness.dart';

void main() {
  group('SelectTool', () {
    late SelectToolTestHarness harness;

    setUp(() => harness = SelectToolTestHarness());

    test('is the active editor tool by default', () {
      expect(harness.context.tool.activeTool, isA<SelectTool>());
    });

    test('deactivation cancels an interaction and clears selection', () {
      final feature = harness.context.document.nodes.first;
      harness.pointerDown(const Offset(50, 50));
      harness.pointerMove(const Offset(70, 80));
      expect(feature.origin, const Offset(20, 30));

      harness.context.tool.activeTool.deactivate(harness.context);

      expect(feature.origin, Offset.zero);
      expect(harness.context.selection.selectedNodeIds, isEmpty);
      expect(harness.context.history.isActive, isFalse);
      expect(harness.context.history.canUndo, isFalse);
    });
  });
}
