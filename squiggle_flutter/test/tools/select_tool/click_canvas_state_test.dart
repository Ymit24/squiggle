import 'package:flutter_test/flutter_test.dart';

import 'select_tool_test_harness.dart';

void main() {
  group('ClickCanvasState', () {
    late SelectToolTestHarness harness;

    setUp(() {
      harness = SelectToolTestHarness();
      harness.context.selection.selectFeature(
        harness.context.document.features.first.id,
      );
    });

    test('clears selection on an empty click', () {
      harness.click(const Offset(500, 500));

      expect(harness.context.selection.selectedFeatures, isEmpty);
    });

    test('shift-click on empty canvas preserves selection', () {
      final selectedId = harness.context.document.features.first.id;

      harness.click(const Offset(500, 500), shift: true);

      expect(harness.context.selection.selectedFeatures, [selectedId]);
    });
  });
}
