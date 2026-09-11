import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

import 'select_tool_test_harness.dart';

void main() {
  group('DragPolylineHandleState', () {
    late SelectToolTestHarness harness;

    setUp(() {
      harness = SelectToolTestHarness(
        context: SelectToolTestHarness.polylineContext(),
      );
      harness.click(const Offset(50, 50));
    });

    test('drags a selected polyline vertex', () {
      final feature = (harness.context.document.nodes.first as Feature);

      harness.pointerDown(const Offset(100, 100));
      harness.pointerMove(const Offset(150, 100));
      harness.pointerUp(const Offset(150, 100));

      expect(polylineWorldPoints(feature).last, const Offset(150, 100));
    });

    test('shift-drag snaps a vertex to a 45 degree angle', () {
      final feature = (harness.context.document.nodes.first as Feature);

      harness.pointerDown(const Offset(100, 100));
      harness.pointerMove(const Offset(140, 120), shift: true);
      harness.pointerUp(const Offset(140, 120), shift: true);

      final point = polylineWorldPoints(feature).last;
      expect(point.dx, closeTo(point.dy, 0.001));
    });

    test('commits one undo entry for a vertex drag', () {
      final feature = (harness.context.document.nodes.first as Feature);

      harness.pointerDown(const Offset(100, 100));
      harness.pointerMove(const Offset(150, 100));
      harness.pointerMove(const Offset(175, 125));
      expect(harness.context.history.canUndo, isFalse);

      harness.pointerUp(const Offset(175, 125));
      expect(polylineWorldPoints(feature).last, const Offset(175, 125));

      harness.context.history.undo();
      expect(polylineWorldPoints(feature).last, const Offset(100, 100));
    });

    test('does not expose vertex handles for multiple selections', () {
      harness.context = EditorContext(
        document: Document.fromFeatures([
          for (final x in [0.0, 200.0])
            Feature(
              origin: Offset(x, 0),
              size: const Size(100, 1),
              kind: const FeatureKindPolyline([
                Offset.zero,
                Offset(100, 0),
              ], strokeColor: Color(0xFFFFFFFF)),
            ),
        ]),
      );
      final features = harness.context.document.nodes.cast<Feature>();
      harness.context.selection.setSelection(
        features.map((feature) => feature.id),
      );
      final pointsBefore = (features.first.kind as FeatureKindPolyline)
          .localPoints
          .toList();

      harness.pointerDown(const Offset(100, 0));
      harness.pointerMove(const Offset(150, 20));
      harness.pointerUp(const Offset(150, 20));

      expect(
        (features.first.kind as FeatureKindPolyline).localPoints,
        pointsBefore,
      );
      expect(features.first.origin, isNot(Offset.zero));
      expect(features.last.origin, isNot(const Offset(200, 0)));
    });
  });
}
