import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/tools/select_tool/helpers.dart';
import 'package:squiggle_flutter/tools/select_tool/resize_handle_util.dart';

import 'select_tool_test_harness.dart';

void main() {
  group('ResizeState', () {
    late SelectToolTestHarness harness;

    setUp(() => harness = SelectToolTestHarness());

    test('dragging every handle past the opposite edge flips the bounds', () {
      final cases = <SelectionResizeHandle, (Offset, Rect)>{
        SelectionResizeHandle.topLeft: (
          const Offset(150, 150),
          const Rect.fromLTWH(100, 100, 50, 50),
        ),
        SelectionResizeHandle.top: (
          const Offset(0, 150),
          const Rect.fromLTWH(0, 100, 100, 50),
        ),
        SelectionResizeHandle.topRight: (
          const Offset(-150, 150),
          const Rect.fromLTWH(-50, 100, 50, 50),
        ),
        SelectionResizeHandle.right: (
          const Offset(-150, 0),
          const Rect.fromLTWH(-50, 0, 50, 100),
        ),
        SelectionResizeHandle.bottomRight: (
          const Offset(-150, -150),
          const Rect.fromLTWH(-50, -50, 50, 50),
        ),
        SelectionResizeHandle.bottom: (
          const Offset(0, -150),
          const Rect.fromLTWH(0, -50, 100, 50),
        ),
        SelectionResizeHandle.bottomLeft: (
          const Offset(150, -150),
          const Rect.fromLTWH(100, -50, 50, 50),
        ),
        SelectionResizeHandle.left: (
          const Offset(150, 0),
          const Rect.fromLTWH(100, 0, 50, 100),
        ),
      };

      for (final entry in cases.entries) {
        final current = SelectToolTestHarness();
        final feature = current.context.document.nodes.first as Feature;
        current.context.selection.selectNode(feature.id);
        final handle = ResizeHandleUtil.getResizeHandles(
          feature,
          current.camera,
        ).firstWhere((handle) => handle.handle == entry.key);
        final down = handle.geometry.center;
        final up = down + entry.value.$1;

        current.pointerDown(down);
        current.pointerMove(up);
        current.pointerUp(up);

        expect(feature.localBounds(), entry.value.$2, reason: '${entry.key}');
        expect(feature.size.width, greaterThanOrEqualTo(0));
        expect(feature.size.height, greaterThanOrEqualTo(0));
      }
    });

    test('shift-resizing past an edge keeps the opposite edge fixed', () {
      for (final (handleType, delta, expected) in [
        (
          SelectionResizeHandle.top,
          const Offset(0, 150),
          const Rect.fromLTWH(25, 100, 50, 50),
        ),
        (
          SelectionResizeHandle.right,
          const Offset(-150, 0),
          const Rect.fromLTWH(-50, 25, 50, 50),
        ),
        (
          SelectionResizeHandle.bottom,
          const Offset(0, -150),
          const Rect.fromLTWH(25, -50, 50, 50),
        ),
        (
          SelectionResizeHandle.left,
          const Offset(150, 0),
          const Rect.fromLTWH(100, 25, 50, 50),
        ),
      ]) {
        final current = SelectToolTestHarness();
        final feature = current.context.document.nodes.first as Feature;
        current.context.selection.selectNode(feature.id);
        final handle = ResizeHandleUtil.getResizeHandles(
          feature,
          current.camera,
        ).firstWhere((handle) => handle.handle == handleType);
        final down = handle.geometry.center;
        final up = down + delta;

        current.pointerDown(down, shift: true);
        current.pointerMove(up, shift: true);
        current.pointerUp(up, shift: true);

        expect(feature.localBounds(), expected, reason: '$handleType');
      }
    });

    test('crossing a corner keeps nested group geometry positive', () {
      final document = harness.context.document;
      document.removeAll(document.nodes.map((node) => node.id).toList());
      final feature = Feature(
        origin: Offset.zero,
        size: const Size(100, 100),
        kind: FeatureKindRectangle(),
      );
      final nested = Group(origin: Offset.zero, children: [feature]);
      final outer = Group(origin: const Offset(100, 200), children: [nested]);
      document.addNode(outer);
      harness.context.selection.selectNode(outer.id);
      final handle = ResizeHandleUtil.getResizeHandles(outer, harness.camera)
          .firstWhere(
            (handle) => handle.handle == SelectionResizeHandle.bottomRight,
          );
      final down = handle.geometry.center;
      final up = down - const Offset(150, 150);

      harness.pointerDown(down);
      harness.pointerMove(up);
      harness.pointerUp(up);

      const expected = Rect.fromLTWH(50, 150, 50, 50);
      expect(outer.localBounds(), expected);
      expect(nested.globalBounds(), expected);
      expect(feature.globalBounds(), expected);
      expect(feature.size, const Size(50, 50));
    });

    test('group drag scales children and restores them through undo/redo', () {
      final document = harness.context.document;
      final children = document.nodes.toList();
      document.removeAll(children.map((node) => node.id));
      final group = Group(origin: const Offset(100, 200), children: children);
      document.addNode(group);
      harness.context.selection.selectNode(group.id);
      final before = document.toDataModel().nodes;
      final down = harness.cornerHitWorldPoint(group.localBounds());
      final up = down + const Offset(300, 100);

      harness.pointerDown(down);
      harness.pointerMove(down);
      expect(document.toDataModel().nodes, before);
      harness.pointerMove(up);
      harness.pointerUp(up);

      expect(group.localBounds(), const Rect.fromLTWH(100, 200, 600, 200));
      expect(
        group.children.first.globalBounds(),
        const Rect.fromLTWH(100, 200, 200, 200),
      );
      expect(
        group.children.last.globalBounds(),
        const Rect.fromLTWH(500, 200, 200, 200),
      );
      final after = document.toDataModel().nodes;
      harness.context.history.undo();
      expect(document.toDataModel().nodes, before);
      expect(harness.context.history.canUndo, isFalse);
      harness.context.history.redo();
      expect(document.toDataModel().nodes, after);
    });

    test('does not snap on first move when corner grab is off-center', () {
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final bounds = feature.localBounds();
      final down = harness.cornerHitWorldPoint(bounds);

      harness.pointerDown(down);
      harness.pointerMove(down);

      expect(feature.localBounds(), bounds);
    });

    test('resizes a single selection from the bottom-right corner', () {
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final bounds = feature.localBounds();
      final down = harness.cornerHitWorldPoint(bounds);
      final grabOffset = down - bounds.bottomRight;

      harness.pointerDown(down);
      harness.pointerMove(const Offset(150, 150) + grabOffset);
      harness.pointerUp(const Offset(150, 150) + grabOffset);

      expect(feature.localBounds(), const Rect.fromLTWH(0, 0, 150, 150));
    });

    test('commits one undo entry for a resize drag', () {
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final bounds = feature.localBounds();
      final down = harness.cornerHitWorldPoint(bounds);
      final grabOffset = down - bounds.bottomRight;

      harness.pointerDown(down);
      harness.pointerMove(const Offset(120, 120) + grabOffset);
      harness.pointerMove(const Offset(160, 160) + grabOffset);

      expect(feature.size, const Size(160, 160));
      expect(harness.context.history.canUndo, isFalse);

      harness.pointerUp(const Offset(160, 160) + grabOffset);
      harness.context.history.undo();
      expect(feature.localBounds(), bounds);
    });

    test('resizes from the top edge', () {
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final bounds = feature.localBounds();
      final down = harness.edgeHitWorldPoint(bounds, SelectionEdge.top);
      final grabOffset = down - bounds.topLeft;

      harness.pointerDown(down);
      harness.pointerMove(const Offset(50, -50) + grabOffset);
      harness.pointerUp(const Offset(50, -50) + grabOffset);

      expect(feature.localBounds(), const Rect.fromLTWH(0, -50, 100, 150));
    });

    test('resizes from the right edge', () {
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final bounds = feature.localBounds();
      final down = harness.edgeHitWorldPoint(bounds, SelectionEdge.right);
      final grabOffset = down - bounds.bottomRight;

      harness.pointerDown(down);
      harness.pointerMove(const Offset(200, 50) + grabOffset);
      harness.pointerUp(const Offset(200, 50) + grabOffset);

      expect(feature.localBounds(), const Rect.fromLTWH(0, 0, 200, 100));
    });

    test('alt-resize from a corner is symmetric around the center', () {
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final bounds = feature.localBounds();
      final down = harness.cornerHitWorldPoint(bounds);
      final grabOffset = down - bounds.bottomRight;

      harness.pointerDown(down, alt: true);
      harness.pointerMove(const Offset(150, 150) + grabOffset, alt: true);
      harness.pointerUp(const Offset(150, 150) + grabOffset, alt: true);

      expect(feature.localBounds().center, bounds.center);
      expect(feature.size, const Size(200, 200));
    });

    test('shift-resize from a corner locks the aspect ratio', () {
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final bounds = feature.localBounds();
      final down = harness.cornerHitWorldPoint(bounds);
      final grabOffset = down - bounds.bottomRight;

      harness.pointerDown(down);
      harness.pointerMove(const Offset(200, 100) + grabOffset, shift: true);
      harness.pointerUp(const Offset(200, 100) + grabOffset, shift: true);

      expect(feature.size.width, closeTo(200, 0.001));
      expect(feature.size.height, closeTo(200, 0.001));
    });

    test('shift-resize from an edge locks the aspect ratio', () {
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final bounds = feature.localBounds();
      final down = harness.edgeHitWorldPoint(bounds, SelectionEdge.bottom);
      final grabOffset = down - bounds.bottomRight;

      harness.pointerDown(down);
      harness.pointerMove(const Offset(50, 200) + grabOffset, shift: true);
      harness.pointerUp(const Offset(50, 200) + grabOffset, shift: true);

      expect(feature.origin.dy, closeTo(0, 0.001));
      expect(feature.size.width, closeTo(200, 0.001));
      expect(feature.size.height, closeTo(200, 0.001));
    });

    test('alt-resize from an edge expands around the center', () {
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final bounds = feature.localBounds();
      final down = harness.edgeHitWorldPoint(bounds, SelectionEdge.top);
      final grabOffset = down - bounds.topLeft;

      harness.pointerDown(down, alt: true);
      harness.pointerMove(const Offset(50, -50) + grabOffset, alt: true);
      harness.pointerUp(const Offset(50, -50) + grabOffset, alt: true);

      expect(feature.localBounds().center, bounds.center);
      expect(feature.size, const Size(100, 200));
    });

    test('does not snap on first move when edge grab is off-center', () {
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final bounds = feature.localBounds();
      final down =
          harness.edgeHitWorldPoint(bounds, SelectionEdge.top) +
          const Offset(10, 0);

      harness.pointerDown(down);
      harness.pointerMove(down);

      expect(feature.localBounds(), bounds);
    });

    test('does not expose resize handles for multiple selections', () {
      final features = harness.context.document.nodes.cast<Feature>();
      harness.context.selection.setSelection(
        features.map((feature) => feature.id),
      );
      final bounds = features.first.localBounds();
      final down = harness.cornerHitWorldPoint(bounds);

      harness.pointerDown(down);
      harness.pointerMove(const Offset(150, 150));
      harness.pointerUp(const Offset(150, 150));

      expect(features.first.localBounds(), bounds);
    });

    test('resizing a polyline scales its points', () {
      harness.context = SelectToolTestHarness.polylineContext();
      final feature = (harness.context.document.nodes.first as Feature);
      harness.click(const Offset(50, 50));
      final endBefore = polylineWorldPoints(feature).last;
      final bounds = feature.localBounds();
      final down = harness.cornerHitWorldPoint(bounds);
      final grabOffset = down - bounds.bottomRight;

      harness.pointerDown(down);
      harness.pointerMove(const Offset(146, 146) + grabOffset);
      harness.pointerUp(const Offset(146, 146) + grabOffset);

      expect(feature.size, const Size(150, 150));
      expect(polylineWorldPoints(feature).last, isNot(endBefore));
    });

    test('corner resize scales text to fill the new bounds', () {
      harness.context = _textContext(
        contents: 'Line one\nLine two\nLine three',
        size: const Size(200, 80),
      );
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final initialFontSize = (feature.kind as FeatureKindText).fontSize;
      final bounds = feature.localBounds();
      final down = harness.cornerHitWorldPoint(bounds);
      final grabOffset = down - bounds.bottomRight;

      harness.pointerDown(down);
      harness.pointerMove(const Offset(300, 300) + grabOffset);
      harness.pointerUp(const Offset(300, 300) + grabOffset);

      final text = feature.kind as FeatureKindText;
      expect(feature.size, const Size(300, 300));
      expect(text.fontSize, greaterThan(initialFontSize));
      expect(
        text.measureContents(width: 300, fontSize: text.fontSize).height,
        lessThanOrEqualTo(300),
      );
    });

    test('vertical resize scales text to fill the taller box', () {
      harness.context = _textContext(
        contents: 'hello world',
        size: const Size(200, 48),
      );
      final feature = (harness.context.document.nodes.first as Feature);
      harness.context.selection.selectNode(feature.id);
      final initialFontSize = (feature.kind as FeatureKindText).fontSize;
      final bounds = feature.localBounds();
      final down = harness.edgeHitWorldPoint(bounds, SelectionEdge.bottom);
      final grabOffset = down - bounds.bottomRight;

      harness.pointerDown(down);
      harness.pointerMove(const Offset(200, 200) + grabOffset);
      harness.pointerUp(const Offset(200, 200) + grabOffset);

      expect(feature.size, const Size(200, 200));
      expect(
        (feature.kind as FeatureKindText).fontSize,
        greaterThan(initialFontSize),
      );
    });
  });
}

EditorContext _textContext({required String contents, required Size size}) =>
    EditorContext(
      document: Document.fromFeatures([
        Feature(
          origin: Offset.zero,
          size: size,
          kind: FeatureKindText(contents, fillColor: const Color(0xFFFFFFFF)),
        ),
      ]),
    );
