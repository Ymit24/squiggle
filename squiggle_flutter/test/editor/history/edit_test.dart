import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/history/history.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node_id.dart';

void main() {
  group('DocumentEdit', () {
    test('records only watched nodes', () {
      final document = Document.fromFeatures([
        _rectangle(1, const Offset(10, 10)),
        _rectangle(2, const Offset(20, 20)),
      ]);
      final moved = document.featureById(NodeId.newId(1))!;
      final untouched = document.featureById(NodeId.newId(2))!;
      final untouchedIdentity = untouched;
      final edit = DocumentTransaction(document: document, label: 'Move');

      edit.watch([moved]);
      moved.origin = const Offset(40, 50);
      final change = edit.commit()!;

      expect(change.affectedNodeCount, 1);
      expect(change.changesOrder, isFalse);
      change.undo(document);
      expect(moved.origin, const Offset(10, 10));
      expect(
        identical(document.featureById(untouched.id), untouchedIdentity),
        isTrue,
      );
      change.redo(document);
      expect(moved.origin, const Offset(40, 50));
    });

    test('returns null when a watched node is unchanged', () {
      final document = Document.fromFeatures([_rectangle(1, Offset.zero)]);
      final feature = document.nodes.single;
      final edit = DocumentTransaction(document: document, label: 'Move');

      edit.watch([feature]);

      expect(edit.commit(), isNull);
    });

    test('cancel restores updates and removes additions', () {
      final document = Document.fromFeatures([_rectangle(1, Offset.zero)]);
      final original = document.nodes.single;
      final edit = DocumentTransaction(document: document, label: 'Duplicate');

      edit.watch([original]);
      original.origin = const Offset(30, 30);
      edit.add(_rectangle(0, const Offset(50, 50)));
      edit.cancel();

      expect(document.nodes, hasLength(1));
      expect(document.nodes.single.id, NodeId.newId(1));
      expect(document.nodes.single.origin, Offset.zero);
    });

    test('undo and redo structural edits preserve order and ids', () {
      final document = Document.fromFeatures([
        _rectangle(1, Offset.zero),
        _rectangle(2, Offset.zero),
        _rectangle(3, Offset.zero),
      ]);
      final edit = DocumentTransaction(document: document, label: 'Replace');

      edit.removeAll([NodeId.newId(2)]);
      final added = edit.add(_rectangle(0, Offset.zero));
      edit.reorder([added.id, NodeId.newId(3), NodeId.newId(1)]);
      final change = edit.commit()!;

      expect(change.changesOrder, isTrue);
      expect(_ids(document), [added.id, NodeId.newId(3), NodeId.newId(1)]);

      change.undo(document);
      expect(_ids(document), [
        NodeId.newId(1),
        NodeId.newId(2),
        NodeId.newId(3),
      ]);

      change.redo(document);
      expect(_ids(document), [added.id, NodeId.newId(3), NodeId.newId(1)]);
    });

    test('update captures before invoking the mutation', () {
      final document = Document.fromFeatures([_rectangle(1, Offset.zero)]);
      final feature = document.nodes.single;
      final edit = DocumentTransaction(document: document, label: 'Move');

      edit.update(feature, (node) => node.origin = const Offset(5, 8));
      final change = edit.commit()!;
      change.undo(document);

      expect(feature.origin, Offset.zero);
    });

    test('captures and restores groups through Node data models', () {
      final group = Group(
        id: NodeId.newId(1),
        origin: const Offset(10, 20),
        children: [_rectangle(2, Offset.zero)],
      );
      final document = Document()..addNode(group);
      final edit = DocumentTransaction(document: document, label: 'Move group');

      edit.update(group, (node) => node.origin = const Offset(40, 50));
      final change = edit.commit()!;
      change.undo(document);

      expect(group.origin, const Offset(10, 20));
      expect(group.children.single, isA<Feature>());
      expect(group.children.single.id, NodeId.newId(2));

      change.redo(document);
      expect(group.origin, const Offset(40, 50));
    });

    test('adds and replays groups', () {
      final document = Document();
      final edit = DocumentTransaction(document: document, label: 'Add group');
      final group = Group(
        origin: Offset.zero,
        children: [_rectangle(2, Offset.zero)],
      );

      edit.add(group);
      final change = edit.commit()!;
      change.undo(document);
      expect(document.nodes, isEmpty);

      change.redo(document);
      expect(document.nodeById(group.id), isA<Group>());
    });

    test('closed edits reject further use', () {
      final document = Document.fromFeatures([_rectangle(1, Offset.zero)]);
      final edit = DocumentTransaction(document: document, label: 'Move');
      edit.commit();

      expect(() => edit.watch(document.nodes), throwsStateError);
    });
  });
}

Feature _rectangle(int id, Offset origin) => Feature(
  id: NodeId.newId(id),
  origin: origin,
  size: const Size(100, 80),
  kind: const FeatureKindRectangle(),
);

List<NodeId> _ids(Document document) => [
  for (final node in document.nodes) node.id,
];
