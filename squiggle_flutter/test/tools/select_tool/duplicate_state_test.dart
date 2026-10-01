import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

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

    test(
      'late alt moves a polyline once, including a new pointer position',
      () {
        harness.context = SelectToolTestHarness.polylineContext();
        final original = harness.context.document.nodes.first;
        harness.pointerDown(const Offset(50, 50));
        harness.pointerMove(const Offset(70, 60));
        harness.pointerMove(const Offset(80, 70), alt: true);
        harness.pointerUp(const Offset(80, 70), alt: true);

        expect(original.origin, Offset.zero);
        final copy = harness.context.document.featureById(
          harness.context.selection.selectedNodeIds.single,
        )!;
        expect(copy.origin, const Offset(30, 20));
      },
    );

    for (final endpoint in ['start', 'end']) {
      for (final cancel in [false, true]) {
        test(
          'late alt restores original $endpoint binding (${cancel ? 'cancel' : 'commit'})',
          () {
            final target = Feature(
              origin: const Offset(100, 0),
              size: const Size(100, 100),
              kind: FeatureKindRectangle(),
            );
            final line = Feature(
              origin: const Offset(0, 50),
              size: Size.zero,
              kind: FeatureKindPolyline([Offset.zero, const Offset(50, 0)]),
            );
            harness.context = EditorContext(
              document: Document.fromFeatures([target, line]),
            );
            final kind = line.kind as FeatureKindPolyline;
            final binding = RadialBinding(target.id, 0);
            if (endpoint == 'start') {
              kind.startBinding = binding;
            } else {
              kind.endBinding = binding;
            }
            target.origin += const Offset(100, 0);
            final before = harness.context.document.toDataModel();
            final points = polylineWorldPoints(line);

            harness.pointerDown(const Offset(150, 50));
            harness.pointerMove(const Offset(170, 60));
            harness.pointerMove(const Offset(180, 70), alt: true);
            final copyId = harness.context.selection.selectedNodeIds.single;
            expect(line.toDataModel(), before.nodes.last);
            final copy = harness.context.document.featureById(copyId)!;
            expect((copy.kind as FeatureKindPolyline).bindings, isEmpty);
            expect(polylineWorldPoints(copy), [
              for (final point in points) point + const Offset(30, 20),
            ]);

            if (cancel) {
              harness.keyDown(LogicalKeyboardKey.escape);
              harness.pointerUp(const Offset(180, 70));
              expect(
                harness.context.document.toDataModel().nodes,
                before.nodes,
              );
              expect(harness.context.history.canUndo, isFalse);
            } else {
              harness.pointerUp(const Offset(180, 70), alt: true);
              final after = harness.context.document.toDataModel();
              harness.context.undo();
              expect(
                harness.context.document.toDataModel().nodes,
                before.nodes,
              );
              expect(harness.context.history.canUndo, isFalse);
              harness.context.redo();
              expect(harness.context.document.toDataModel().nodes, after.nodes);
            }
          },
        );
      }
    }

    for (final lateAlt in [false, true]) {
      test(
        '${lateAlt ? 'late' : 'initial'} alt drag retains copied connections',
        () {
          final target = Feature(
            origin: const Offset(200, 0),
            size: const Size(100, 100),
            kind: FeatureKindRectangle(),
          );
          final line = Feature(
            origin: const Offset(0, 50),
            size: Size.zero,
            kind: FeatureKindPolyline([Offset.zero, const Offset(100, 0)]),
          );
          harness.context = EditorContext(
            document: Document.fromFeatures([line, target]),
          );
          (line.kind as FeatureKindPolyline).endBinding = RadialBinding(
            target.id,
            0,
          );
          final before = harness.context.document.toDataModel();
          harness.context.selection.setSelection([line.id, target.id]);

          harness.pointerDown(const Offset(100, 50), alt: !lateAlt);
          if (lateAlt) {
            harness.pointerMove(const Offset(110, 55));
          }
          harness.pointerMove(const Offset(120, 60), alt: true);
          harness.pointerMove(const Offset(140, 80), alt: true);
          harness.pointerUp(const Offset(140, 80), alt: true);

          final copies = harness.context.selection.selectedNodeIds
              .map((id) => harness.context.document.featureById(id)!)
              .toList();
          final copiedLine = copies.first;
          final copiedTarget = copies.last;
          expect(
            (copiedLine.kind as FeatureKindPolyline).endBinding!.targetId,
            copiedTarget.id,
          );
          expect(polylineWorldPoints(copiedLine), [
            const Offset(40, 80),
            const Offset(340, 80),
          ]);
          final after = harness.context.document.toDataModel();
          harness.context.undo();
          expect(harness.context.document.toDataModel().nodes, before.nodes);
          harness.context.redo();
          expect(harness.context.document.toDataModel().nodes, after.nodes);
        },
      );
    }

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
