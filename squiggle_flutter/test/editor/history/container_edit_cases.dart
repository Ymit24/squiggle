import 'dart:ui';
import 'package:data_models/data_models.dart' as data;

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/history/edit.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';

void main() {
  test('duplicated subtrees receive fresh IDs and replay independently', () {
    final original = Group(origin: Offset.zero, children: [rect(12)]);
    final doc = Document()..insert(original);
    final edit = DocumentTransaction(document: doc, label: 'Duplicate');
    final copy = edit.add(original.copyWith(id: noId));
    expect(copy.children.single.id, isNot(original.children.single.id));
    final copiedChildId = copy.children.single.id;
    final change = edit.commit()!;
    change.undo(doc);
    expect(doc.nodeById(copiedChildId), isNull);
    expect(
      doc.nodeById(original.children.single.id),
      same(original.children.single),
    );
    change.redo(doc);
    expect(doc.nodeById(copiedChildId)!.parent, same(doc.nodeById(copy.id)));
    final loaded = Document.fromDataModel(doc.toDataModel());
    expect(
      loaded.nodeById(copiedChildId)!.parent,
      same(loaded.nodeById(copy.id)),
    );
    expect(loaded.generateId().value, greaterThan(copiedChildId.value));
  });

  test('containers maintain ownership, views and global descendant IDs', () {
    final child = rect(40);
    final group = Group(origin: Offset.zero, children: [child]);
    final doc = Document()..insert(group);
    final roots = doc.nodes;
    expect(identical(roots, doc.nodes), isTrue);
    expect(child.parent, same(group));
    expect(group.parent, same(doc));
    expect(doc.nodeById(child.id), same(child));
    expect(doc.childById(child.id), isNull);
    expect(group.childById(child.id), same(child));
    final added = group.insert(rect());
    expect(added.id.value, greaterThan(40));
    expect(doc.nodeById(added.id), same(added));
    expect(() => roots.clear(), throwsUnsupportedError);
    doc.removeAll([group.id]);
    expect(roots, isEmpty);
    expect(group.parent, isNull);
    expect(child.parent, same(group));
    expect(doc.nodeById(child.id), isNull);
    doc.insert(group);
    expect(doc.nodeById(child.id), same(child));
  });

  test('group, edit child, ungroup and replay recreated containers', () {
    final a = rect(1)..origin = const Offset(20, 30);
    final b = rect(2)..origin = const Offset(40, 50);
    final untouched = rect(3);
    final doc = Document.fromFeatures([a, untouched, b]);
    final grouping = DocumentTransaction(document: doc, label: 'Group');
    grouping.removeAll([a.id, b.id]);
    a.origin -= const Offset(10, 10);
    b.origin -= const Offset(10, 10);
    final group = grouping.add(
      Group(origin: const Offset(10, 10), children: [a, b]),
    );
    final grouped = grouping.commit()!;

    final move = DocumentTransaction(
      document: doc,
      container: group,
      label: 'Move',
    );
    move.update(a, (node) => node.origin = const Offset(90, 90));
    final moved = move.commit()!;
    final ungroup = DocumentTransaction(document: doc, label: 'Ungroup');
    ungroup.removeAll([group.id]);
    final children = group.children.toList();
    group.removeAll(children.map((node) => node.id));
    for (final child in children) {
      child.origin += group.origin;
      ungroup.add(child);
    }
    final ungrouped = ungroup.commit()!;

    for (var cycle = 0; cycle < 2; cycle++) {
      ungrouped.undo(doc);
      final recreated = doc.nodeById(group.id) as Group;
      expect(recreated, isNot(same(group)));
      expect(doc.nodeById(a.id)!.parent, same(recreated));
      moved.undo(doc);
      expect(doc.nodeById(a.id)!.origin, const Offset(10, 20));
      grouped.undo(doc);
      expect(doc.nodes.map((node) => node.id), [a.id, untouched.id, b.id]);
      expect(doc.nodeById(a.id)!.origin, const Offset(20, 30));
      expect(doc.nodeById(group.id), isNull);
      expect(doc.nodeById(untouched.id), same(untouched));
      grouped.redo(doc);
      moved.redo(doc);
      expect(doc.nodeById(a.id)!.origin, const Offset(90, 90));
      ungrouped.redo(doc);
      expect(doc.nodeById(a.id)!.origin, const Offset(100, 100));
      expect(doc.nodeById(a.id)!.parent, same(doc));
      expect(doc.nodeById(group.id), isNull);
    }
  });

  test('nested grouping cancellation restores only its container', () {
    final a = rect(1), b = rect(2);
    final parent = Group(origin: Offset.zero, children: [a, b]);
    final doc = Document()..insert(parent);
    final edit = DocumentTransaction(
      document: doc,
      container: parent,
      label: 'Group',
    );
    edit.removeAll([a.id, b.id]);
    final added = edit.add(Group(origin: Offset.zero, children: [a, b]));
    edit.cancel();
    expect(parent.children.map((node) => node.id), [a.id, b.id]);
    expect(doc.nodeById(added.id), isNull);
    expect(doc.nodeById(a.id)!.parent, same(parent));
    expect(doc.nodes.single, same(parent));
  });

  test('nested stacking and deletion restore order and global index', () {
    final a = rect(1), b = rect(2), c = rect(3);
    final parent = Group(origin: Offset.zero, children: [a, b, c]);
    final doc = Document()..insert(parent);
    final reorder = DocumentTransaction(
      document: doc,
      container: parent,
      label: 'Front',
    );
    reorder.reorder([b.id, c.id, a.id]);
    final order = reorder.commit()!;
    expect(order.affectedNodeCount, 0);
    order.undo(doc);
    expect(parent.children, [a, b, c]);
    order.redo(doc);
    final delete = DocumentTransaction(
      document: doc,
      container: parent,
      label: 'Delete',
    );
    delete.removeAll([a.id, c.id]);
    final removed = delete.commit()!;
    expect(doc.nodeById(a.id), isNull);
    removed.undo(doc);
    expect(parent.children.map((node) => node.id), [b.id, c.id, a.id]);
    expect(doc.nodeById(c.id)!.parent, same(parent));
    removed.redo(doc);
    expect(parent.children.single, same(b));
  });

  test('failed capture leaves edit open and cancellable', () {
    final node = FailingFeature();
    final doc = Document()..insert(node);
    final edit = DocumentTransaction(document: doc, label: 'Move');
    edit.watch([node]);
    node.origin = const Offset(5, 5);
    node.fail = true;
    expect(edit.commit, throwsStateError);
    expect(edit.isOpen, isTrue);
    edit.cancel();
    expect(node.origin, Offset.zero);
  });

  test('rejects foreign children, duplicate subtree IDs and cycles', () {
    final child = rect(9);
    final group = Group(origin: Offset.zero, children: [child]);
    final doc = Document()..insert(group);
    final edit = DocumentTransaction(document: doc, label: 'Root');
    expect(() => edit.watch([child]), throwsArgumentError);
    expect(() => doc.insert(child), throwsStateError);
    final duplicate = Group(origin: Offset.zero, children: [rect(9)]);
    expect(() => doc.insert(duplicate), throwsArgumentError);
    expect(duplicate.parent, isNull);
    expect(doc.nodeById(child.id), same(child));
    doc.removeAll([group.id]);
    expect(() => group.insert(group), throwsStateError);
  });
}

Feature rect([int id = 0]) => Feature(
  id: NodeId.newId(id),
  origin: Offset.zero,
  size: const Size(10, 10),
  kind: FeatureKindRectangle(),
);

class FailingFeature extends Feature {
  FailingFeature()
    : super(
        origin: Offset.zero,
        size: const Size(10, 10),
        kind: FeatureKindRectangle(),
      );
  bool fail = false;
  @override
  data.Feature toDataModel() {
    if (fail) throw StateError('Capture failed');
    return super.toDataModel();
  }
}
