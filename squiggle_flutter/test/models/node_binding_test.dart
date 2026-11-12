import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/history/history.dart';
import 'package:squiggle_flutter/editor/selection_model.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_binding.dart';
import 'package:squiggle_flutter/services/duplicate_nodes.dart';

Feature _box(Offset origin, {FeatureKind? kind}) => Feature(
  origin: origin,
  size: const Size(100, 100),
  kind: kind ?? FeatureKindRectangle(),
);

Feature _line(Offset from, Offset to, {Node? start, Node? end}) => Feature(
  origin: from,
  size: Size.zero,
  kind: FeatureKindPolyline(
    [Offset.zero, to - from],
    startBinding: start == null ? null : NodeBinding(start.id),
    endBinding: end == null ? null : NodeBinding(end.id),
  ),
);

List<Offset> _resolved(Feature line) =>
    (line.kind as FeatureKindPolyline).resolvedPoints(line);

List<Offset> _stored(Feature line) {
  final kind = line.kind as FeatureKindPolyline;
  return [for (final point in kind.localPoints) line.origin + point];
}

void main() {
  late Document document;
  late Feature left;
  late Feature right;

  setUp(() {
    document = Document();
    left = document.insert(_box(Offset.zero));
    right = document.insert(_box(const Offset(300, 0)));
  });

  Feature addLine({bool bindStart = true, bool bindEnd = true}) =>
      document.insert(
        _line(
          const Offset(50, 50),
          const Offset(350, 50),
          start: bindStart ? left : null,
          end: bindEnd ? right : null,
        ),
      );

  group('resolution', () {
    test('bound ends sit on the facing outlines and follow targets', () {
      final line = addLine();
      expect(_resolved(line), [const Offset(100, 50), const Offset(300, 50)]);

      right.origin = const Offset(300, 200);
      // Aimed at the other target's center, the end lands on the near edge.
      final end = _resolved(line).last;
      expect(end.dx, closeTo(300, 0.001));
      expect(end.dy, closeTo(250 - 200 / 6, 0.001));
    });

    test('circle targets clip to the ellipse', () {
      final circle = document.insert(
        _box(const Offset(300, 300), kind: FeatureKindCircle()),
      );
      final line = document.insert(
        _line(const Offset(0, 0), const Offset(350, 350), end: circle),
      );
      final end = _resolved(line).last;
      expect((end - const Offset(350, 350)).distance, closeTo(50, 0.001));
    });

    test('an end aims from its neighbouring point on longer polylines', () {
      final line = document.insert(
        Feature(
          origin: const Offset(50, -100),
          size: Size.zero,
          kind: FeatureKindPolyline(const [
            Offset.zero,
            Offset(300, 0),
            Offset(300, 150),
          ], endBinding: NodeBinding(right.id)),
        ),
      );
      expect(_resolved(line).last, const Offset(350, 0));
    });

    test('missing targets fall back to stored points', () {
      final line = addLine();
      document.removeAll([right.id]);
      expect(_resolved(line).last, const Offset(350, 50));
    });

    test('lines inside groups resolve in their parent space', () {
      final line = _line(const Offset(0, 0), const Offset(10, 0), end: right);
      document.insert(Group(origin: const Offset(100, 100), children: [line]));
      expect(_resolved(line).last, const Offset(200, -40));
    });

    test('binding cycles through groups terminate', () {
      final a = Group(origin: Offset.zero, children: [_box(Offset.zero)]);
      final b = Group(
        origin: const Offset(500, 0),
        children: [_box(Offset.zero)],
      );
      document.insert(a);
      document.insert(b);
      a.insert(_line(Offset.zero, const Offset(10, 0), end: b));
      b.insert(_line(Offset.zero, const Offset(10, 0), end: a));
      expect(a.localBounds().isFinite, isTrue);
    });

    test('bindings survive serialization and clone', () {
      final line = addLine();
      final restored = Feature.fromDataModel(line.toDataModel());
      final kind = restored.kind as FeatureKindPolyline;
      expect(kind.startBinding?.targetId, left.id);
      expect(kind.endBinding?.targetId, right.id);
      final clone = line.copyWith().kind as FeatureKindPolyline;
      expect(clone.endBinding?.targetId, right.id);
    });

    test('lines and their ancestors are not bind targets', () {
      final line = _line(Offset.zero, const Offset(10, 0));
      final group = Group(origin: Offset.zero, children: [line]);
      document.insert(group);
      expect(canBindTo(line), isFalse);
      expect(canBindTo(group, line: line), isFalse);
      expect(canBindTo(left, line: line), isTrue);
    });
  });

  group('history', () {
    late History history;
    setUp(() => history = History(document: document));

    test('moving a target refreshes the stored points of bound lines', () {
      final line = addLine();
      history.run('Move', (transaction) {
        transaction.update(right, (node) => node.origin = const Offset(500, 0));
      });
      expect(_stored(line).last, const Offset(500, 50));

      history.undo();
      expect(_resolved(line).last, const Offset(300, 50));
    });

    test('deleting a target leaves the line where it was drawn', () {
      final line = addLine();
      right.origin = const Offset(500, 0);
      history.run('Delete', (transaction) => transaction.removeAll([right.id]));
      expect(_resolved(line).last, const Offset(500, 50));

      // Structural undo rebuilds both nodes from their snapshots.
      history.undo();
      document.featureById(right.id)!.origin = const Offset(600, 0);
      final restoredLine = document.featureById(line.id)!;
      expect(_resolved(restoredLine).last, const Offset(600, 50));
    });
  });

  group('copies', () {
    late History history;
    setUp(() => history = History(document: document));

    List<Node> duplicate(List<Node> nodes) {
      late List<Node> copies;
      history.run('Duplicate', (transaction) {
        copies = duplicateNodes(
          nodes: nodes,
          transaction: transaction,
          selection: SelectionModel(),
          offset: const Offset(0, 1000),
        );
      });
      return copies;
    }

    test('bindings between copied nodes follow the copies', () {
      final line = addLine();
      final copies = duplicate([left, line, right]);
      final copiedLine = copies[1] as Feature;
      final kind = copiedLine.kind as FeatureKindPolyline;
      expect(kind.startBinding?.targetId, copies[0].id);
      expect(kind.endBinding?.targetId, copies[2].id);
    });

    test('bindings to uncopied nodes are dropped where they resolved', () {
      final line = addLine();
      final copiedLine = duplicate([line]).single as Feature;
      final kind = copiedLine.kind as FeatureKindPolyline;
      expect(kind.bindings, isEmpty);
      expect(_resolved(copiedLine), [
        const Offset(100, 1050),
        const Offset(300, 1050),
      ]);
    });
  });
}
