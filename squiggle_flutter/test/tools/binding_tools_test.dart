import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';
import 'package:squiggle_flutter/tools/create_line_tool.dart';
import 'package:squiggle_flutter/tools/select_tool/selection_painter.dart';

import 'select_tool/select_tool_test_harness.dart';

Feature _box(Offset origin) => Feature(
  origin: origin,
  size: const Size(100, 100),
  kind: FeatureKindRectangle(),
);

void main() {
  late SelectToolTestHarness harness;
  late Feature left;
  late Feature right;

  setUp(() {
    left = _box(Offset.zero);
    right = _box(const Offset(300, 0));
    harness = SelectToolTestHarness(
      context: EditorContext(document: Document.fromFeatures([left, right])),
    );
  });

  EditorContext context() => harness.context;

  Feature drawLine(Offset from, Offset to, {bool command = false}) {
    context().setTool(CreateLineTool());
    harness
      ..pointerDown(from, command: command)
      ..pointerMove(to, command: command)
      ..pointerUp(to, command: command);
    return context().document.nodes.last as Feature;
  }

  FeatureKindPolyline kindOf(Feature line) => line.kind as FeatureKindPolyline;

  List<Offset> resolved(Feature line) => kindOf(line).resolvedPoints(line);

  group('creating lines', () {
    test('ends drawn over shapes bind to them', () {
      final line = drawLine(const Offset(50, 50), const Offset(350, 50));
      expect(kindOf(line).startBinding?.targetId, left.id);
      expect(kindOf(line).endBinding?.targetId, right.id);
      expect(resolved(line), [const Offset(100, 50), const Offset(300, 50)]);
    });

    test('Ctrl or Cmd places ends freely', () {
      final line = drawLine(
        const Offset(50, 50),
        const Offset(350, 50),
        command: true,
      );
      expect(kindOf(line).bindings, isEmpty);
      expect(resolved(line).last, const Offset(350, 50));
    });

    test('both ends never bind to the same shape', () {
      final line = drawLine(const Offset(20, 50), const Offset(80, 50));
      expect(kindOf(line).startBinding?.targetId, left.id);
      expect(kindOf(line).endBinding, isNull);
    });

    test('lines are not bind targets', () {
      final first = drawLine(const Offset(500, 0), const Offset(500, 300));
      final second = drawLine(const Offset(400, 150), const Offset(500, 150));
      expect(kindOf(first).bindings, isEmpty);
      expect(kindOf(second).bindings, isEmpty);
    });
  });

  group('editing bound lines', () {
    late Feature line;

    List<int> handleFills() {
      final canvas = _HandleCanvas();
      SelectionPainter.paintSelectedPolylineHandles(
        canvas,
        harness.camera,
        context(),
      );
      return canvas.fills;
    }

    setUp(() {
      line = drawLine(const Offset(50, 50), const Offset(350, 50));
      harness.click(const Offset(200, 50));
      expect(context().selection.selectedNodeIds, [line.id]);
    });

    test('handles show an end as attached only while its target exists', () {
      final accent = SquiggleColors.accent.toARGB32();
      expect(handleFills(), [accent, accent]);

      context().history.run(
        'Delete',
        (transaction) => transaction.removeAll([right.id]),
      );
      expect(kindOf(line).endBinding, isNotNull);
      expect(handleFills(), [accent, SquiggleColors.base.toARGB32()]);
    });

    test('moving the line alone detaches it where it was', () {
      harness
        ..pointerDown(const Offset(200, 50))
        ..pointerMove(const Offset(200, 250))
        ..pointerUp(const Offset(200, 250));
      expect(kindOf(line).bindings, isEmpty);
      expect(resolved(line), [const Offset(100, 250), const Offset(300, 250)]);

      context().undo();
      final restored = context().document.featureById(line.id)!;
      expect(kindOf(restored).bindings, hasLength(2));
    });

    test('Alt mid-drag duplicates and leaves the original bound', () {
      harness
        ..pointerDown(const Offset(200, 50))
        ..pointerMove(const Offset(200, 150))
        ..pointerMove(const Offset(200, 250), alt: true)
        ..pointerUp(const Offset(200, 250), alt: true);
      expect(kindOf(line).bindings, hasLength(2));
      final copy = context().document.nodes.last as Feature;
      expect(copy.id, isNot(line.id));
      expect(kindOf(copy).bindings, isEmpty);
    });

    test('moving the line with its targets keeps it bound', () {
      context().selection.setSelection([left.id, line.id, right.id]);
      harness
        ..pointerDown(const Offset(200, 50))
        ..pointerMove(const Offset(200, 250))
        ..pointerUp(const Offset(200, 250));
      expect(kindOf(line).bindings, hasLength(2));
      expect(resolved(line), [const Offset(100, 250), const Offset(300, 250)]);
    });

    test('dragging an end off its shape unbinds it, onto one binds it', () {
      harness
        ..pointerDown(const Offset(300, 50))
        ..pointerMove(const Offset(600, 50))
        ..pointerUp(const Offset(600, 50));
      expect(kindOf(line).endBinding, isNull);
      expect(resolved(line).last, const Offset(600, 50));

      harness
        ..pointerDown(const Offset(600, 50))
        ..pointerMove(const Offset(330, 30))
        ..pointerUp(const Offset(330, 30));
      expect(kindOf(line).endBinding?.targetId, right.id);
      expect(resolved(line).last, const Offset(300, 50));
    });

    test('Ctrl or Cmd drops a dragged end without binding', () {
      harness
        ..pointerDown(const Offset(300, 50))
        ..pointerMove(const Offset(330, 30), command: true)
        ..pointerUp(const Offset(330, 30), command: true);
      expect(kindOf(line).endBinding, isNull);
      expect(resolved(line).last, const Offset(330, 30));
    });

    test('dragging an end onto the other end\'s shape does not bind', () {
      harness
        ..pointerDown(const Offset(300, 50))
        ..pointerMove(const Offset(30, 30))
        ..pointerUp(const Offset(30, 30));
      expect(kindOf(line).endBinding, isNull);
    });

    test('handles grab bound ends where they resolve', () {
      right.origin = const Offset(300, 300);
      harness
        ..pointerDown(resolved(line).last)
        ..pointerMove(const Offset(700, 700))
        ..pointerUp(const Offset(700, 700));
      expect(kindOf(line).endBinding, isNull);
      expect(resolved(line).last, const Offset(700, 700));
    });
  });
}

/// Records the fill colour (as ARGB) of each vertex handle painted.
class _HandleCanvas implements Canvas {
  final fills = <int>[];

  @override
  void drawCircle(Offset center, double radius, Paint paint) {
    if (paint.style == PaintingStyle.fill) fills.add(paint.color.toARGB32());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
