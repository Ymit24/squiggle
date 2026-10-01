import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/editor/grouping_commands.dart';
import 'package:squiggle_flutter/editor/history/history.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';

void main() {
  late Document document;
  late History history;
  late Feature first;
  late Feature second;
  late Feature line;

  setUp(() {
    document = Document();
    first = rectangle(const Offset(200, 0));
    second = rectangle(const Offset(400, 0));
    line = CountingLine();
    document.addNodes([first, second, line]);
    kind(line).startBinding = RadialBinding(first.id, 0);
    kind(line).endBinding = RadialBinding(second.id, 0);
    history = History(document: document);
  });

  test('deletion preserves current geometry, other bindings, and reload', () {
    // Change the target without painting or otherwise warming a cache.
    first.origin = const Offset(250, 100);
    first.size = const Size(150, 80);
    final before = document.toDataModel().nodes;
    const visible = [Offset(400, 140), Offset(50, 20), Offset(500, 50)];
    final lineId = line.id;
    final firstId = first.id;
    final secondId = second.id;

    history.run('Delete', (edit) => edit.removeAll([firstId]));
    expect(document.nodeById(firstId), isNull);
    expect(kind(line).startBinding, isNull);
    expect(kind(line).endBinding?.targetId, secondId);
    expectPoints(points(line), visible);
    final after = document.toDataModel().nodes;

    final loaded = Document.fromDataModel(document.toDataModel());
    expectPoints(points(loaded.featureById(lineId)!), visible);
    expect(kind(loaded.featureById(lineId)!).startBinding, isNull);

    for (var cycle = 0; cycle < 2; cycle++) {
      history.undo();
      expect(document.toDataModel().nodes, before);
      expect(
        kind(document.featureById(lineId)!).startBinding?.targetId,
        firstId,
      );
      history.redo();
      expect(document.toDataModel().nodes, after);
      expectPoints(points(document.featureById(lineId)!), visible);
    }
    expect(history.canUndo, isTrue);
    history.undo();
    expect(history.canUndo, isFalse);
  });

  test('both targets in one removal notify a source only once', () {
    final visible = points(line);
    history.run('Delete', (edit) => edit.removeAll([first.id, second.id]));
    expect(kind(line).bindings, isEmpty);
    expectPoints(points(line), visible);
    expect((line as CountingLine).geometryUpdates, 1);
  });

  test('both endpoints bound to one target detach together', () {
    kind(line).endBinding = RadialBinding(first.id, 0);
    final visible = points(line);
    history.run('Delete', (edit) => edit.removeAll([first.id]));
    expect(kind(line).bindings, isEmpty);
    expectPoints(points(line), visible);
    expect((line as CountingLine).geometryUpdates, 1);
  });

  test('sources being deleted are not notified', () {
    final sourceBefore = line.toDataModel();
    history.run('Delete', (edit) => edit.removeAll([first.id, line.id]));
    expect(line.toDataModel(), sourceBefore);
    expect((line as CountingLine).geometryUpdates, 0);
  });

  test('unrelated deletion does not capture or mutate a source', () {
    final unrelated = document.addNode(rectangle(const Offset(600, 0)));
    final sourceBefore = line.toDataModel();
    final edit = DocumentTransaction(document: document, label: 'Delete');
    edit.removeAll([unrelated.id]);
    expect(edit.commit()!.affectedNodeCount, 1);
    expect(line.toDataModel(), sourceBefore);
  });

  test('group deletion includes its targets and skips its sources', () {
    final inside = CountingLine();
    document.removeAll([first.id, second.id]);
    final group = Group(
      origin: const Offset(50, 20),
      children: [first, second, inside],
    );
    document.addNode(group);
    kind(inside).startBinding = RadialBinding(first.id, 0);
    final before = document.toDataModel().nodes;
    final visible = points(line);
    final lineId = line.id;

    history.run('Delete', (edit) => edit.removeAll([group.id]));
    expect(kind(line).bindings, isEmpty);
    expectPoints(points(line), visible);
    expect(inside.geometryUpdates, 0);
    history.undo();
    expect(document.toDataModel().nodes, before);
    expect(kind(document.featureById(lineId)!).bindings, hasLength(2));
  });

  test('scoped deletion captures sources in another group and cancels', () {
    document.removeAll([first.id, line.id]);
    final targetGroup = Group(origin: const Offset(100, 20), children: [first]);
    final sourceGroup = Group(origin: const Offset(30, 40), children: [line]);
    document.addNodes([targetGroup, sourceGroup]);
    final before = document.toDataModel().nodes;
    final visible = points(line);
    final lineId = line.id;

    history.begin('Delete', container: targetGroup);
    history.active.removeAll([first.id]);
    expect(kind(line).startBinding, isNull);
    expectPoints(points(line), visible);
    history.cancel();
    expect(document.toDataModel().nodes, before);

    history.run(
      'Delete',
      (edit) => edit.removeAll([first.id]),
      container: targetGroup,
    );
    final after = document.toDataModel().nodes;
    history.undo();
    expect(document.toDataModel().nodes, before);
    history.redo();
    expect(document.toDataModel().nodes, after);
    expectPoints(points(document.featureById(lineId)!), visible);
    expect(document.featureById(lineId)!.parent, same(sourceGroup));
  });

  test(
    'an earlier ancestor snapshot covers a source without overriding undo',
    () {
      document.removeAll([line.id]);
      final group = Group(origin: Offset.zero, children: [line]);
      document.addNode(group);
      final before = document.toDataModel().nodes;

      history.run('Move and delete', (edit) {
        edit.update(group, (node) => node.origin = const Offset(20, 30));
        edit.removeAll([first.id]);
      });
      final after = document.toDataModel().nodes;
      history.undo();
      expect(document.toDataModel().nodes, before);
      history.redo();
      expect(document.toDataModel().nodes, after);
    },
  );

  test(
    'source snapshots survive its group being removed later in the edit',
    () {
      document.removeAll([line.id]);
      final group = Group(origin: const Offset(20, 30), children: [line]);
      document.addNode(group);
      final before = document.toDataModel().nodes;

      history.run('Delete', (edit) {
        edit.removeAll([first.id]);
        edit.removeAll([group.id]);
      });
      final after = document.toDataModel().nodes;
      history.undo();
      expect(document.toDataModel().nodes, before);
      history.redo();
      expect(document.toDataModel().nodes, after);
    },
  );

  test('grouping and ungrouping preserve external bindings and geometry', () {
    final context = EditorContext(document: document);
    final visible = points(line);
    final sourceBefore = line.toDataModel();
    context.selection.setSelection([first.id, second.id]);
    groupSelectedNodes(context);
    expect(line.toDataModel(), sourceBefore);
    expectPoints(points(line), visible);
    ungroupSelectedNodes(context);
    expect(line.toDataModel(), sourceBefore);
    expectPoints(points(line), visible);
    context.history.undo();
    context.history.undo();
    expect(line.toDataModel(), sourceBefore);
    expectPoints(points(line), visible);
    context.history.redo();
    context.history.redo();
    expect(line.toDataModel(), sourceBefore);
    expectPoints(points(line), visible);
  });
}

Feature rectangle(Offset origin) => Feature(
  origin: origin,
  size: const Size(100, 100),
  kind: FeatureKindRectangle(),
);

FeatureKindPolyline kind(Feature feature) =>
    feature.kind as FeatureKindPolyline;

List<Offset> points(Feature feature) =>
    kind(feature).resolvedGlobalPoints(feature);

void expectPoints(List<Offset> actual, List<Offset> expected) {
  expect(actual, hasLength(expected.length));
  for (var i = 0; i < actual.length; i++) {
    expect((actual[i] - expected[i]).distance, closeTo(0, 1e-8));
  }
}

class CountingLine extends Feature {
  CountingLine()
    : super(
        origin: Offset.zero,
        size: Size.zero,
        kind: FeatureKindPolyline([
          Offset.zero,
          const Offset(50, 20),
          const Offset(100, 50),
        ]),
      );

  int geometryUpdates = 0;

  @override
  Rect localBounds() {
    geometryUpdates++;
    return super.localBounds();
  }
}
