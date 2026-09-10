import 'package:flutter_test/flutter_test.dart';

import 'select_tool_test_harness.dart';

void main() {
  group('ClickNodeState', () {
    late SelectToolTestHarness harness;

    setUp(() => harness = SelectToolTestHarness());

    test('selects a node on click', () {
      harness.click(const Offset(50, 50));

      expect(harness.context.selection.selectedFeatures, [
        harness.context.document.features.first.id,
      ]);
    });

    test('switches selection when clicking another node', () {
      harness.click(const Offset(50, 50));
      harness.click(const Offset(250, 50));

      expect(harness.context.selection.selectedFeatures, [
        harness.context.document.features[1].id,
      ]);
    });

    test('shift-click adds and removes nodes from selection', () {
      harness.click(const Offset(50, 50));
      harness.click(const Offset(250, 50), shift: true);
      harness.click(const Offset(50, 50), shift: true);

      expect(harness.context.selection.selectedFeatures, [
        harness.context.document.features[1].id,
      ]);
    });

    test('alt-click without a drag does not duplicate', () {
      harness.click(const Offset(50, 50), alt: true);

      expect(harness.context.document.features, hasLength(2));
    });
  });
}
