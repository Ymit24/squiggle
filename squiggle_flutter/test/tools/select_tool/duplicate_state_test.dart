import 'package:flutter_test/flutter_test.dart';

import 'select_tool_test_harness.dart';

void main() {
  group('DuplicateState', () {
    late SelectToolTestHarness harness;

    setUp(() => harness = SelectToolTestHarness());

    test('alt-drag duplicates a node and leaves the original in place', () {
      final original = harness.context.document.nodes.first;

      harness.pointerDown(const Offset(50, 50), alt: true);
      harness.pointerMove(const Offset(70, 80), alt: true);
      harness.pointerUp(const Offset(70, 80), alt: true);

      expect(harness.context.document.nodes, hasLength(3));
      expect(original.origin, Offset.zero);
      final duplicate = harness.context.document.featureById(
        harness.context.selection.selectedNodeIds.single,
      )!;
      expect(duplicate.id, isNot(original.id));
      expect(duplicate.origin, const Offset(20, 30));
    });

    test('alt-drag duplicates all selected nodes', () {
      final features = harness.context.document.nodes;
      harness.click(const Offset(50, 50));
      harness.click(const Offset(250, 50), shift: true);

      harness.pointerDown(const Offset(50, 50), alt: true);
      harness.pointerMove(const Offset(60, 60), alt: true);
      harness.pointerUp(const Offset(60, 60), alt: true);

      expect(harness.context.document.nodes, hasLength(4));
      expect(features[0].origin, Offset.zero);
      expect(features[1].origin, const Offset(200, 0));
      expect(
        harness.context.selection.selectedNodeIds
            .map((id) => harness.context.document.featureById(id)!.origin)
            .toSet(),
        {const Offset(10, 10), const Offset(210, 10)},
      );
    });

    test('pressing alt during a drag duplicates at the current position', () {
      final original = harness.context.document.nodes.first;
      harness.pointerDown(const Offset(50, 50));
      harness.pointerMove(const Offset(70, 60));
      harness.pointerMove(const Offset(70, 60), alt: true);
      harness.pointerMove(const Offset(90, 80), alt: true);
      harness.pointerUp(const Offset(90, 80), alt: true);

      expect(original.origin, Offset.zero);
      expect(
        harness.context.document
            .featureById(harness.context.selection.selectedNodeIds.single)!
            .origin,
        const Offset(40, 30),
      );
    });

    test('duplicate drag replays as one history entry', () {
      final original = harness.context.document.nodes.first;
      harness.pointerDown(const Offset(50, 50));
      harness.pointerMove(const Offset(70, 80), alt: true);
      harness.pointerMove(const Offset(90, 100), alt: true);
      harness.pointerUp(const Offset(90, 100), alt: true);
      final duplicateId = harness.context.selection.selectedNodeIds.single;
      final finalOrigin = harness.context.document
          .nodeById(duplicateId)!
          .origin;

      harness.context.history.undo();
      expect(harness.context.document.nodeById(duplicateId), isNull);
      expect(original.origin, Offset.zero);
      expect(harness.context.history.canUndo, isFalse);

      harness.context.history.redo();
      expect(
        harness.context.document.nodeById(duplicateId)!.origin,
        finalOrigin,
      );
    });
  });
}
