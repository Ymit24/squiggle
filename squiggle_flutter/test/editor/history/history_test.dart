import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:squiggle_flutter/editor/history/history.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/group.dart';

void main() {
  late Document document;
  late History history;
  late Feature node;

  setUp(() {
    document = Document();
    node = document.insert(_rectangle());
    history = History(document);
  });

  void move(double x) => history.run('Move', (transaction) {
    transaction.update(node, (node) => node.origin = Offset(x, 0));
  });

  test('commits multiple actions and replays them in order', () {
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isFalse);
    move(10);
    move(20);
    expect(history.isActive, isFalse);
    expect(node.origin, const Offset(20, 0));

    history.undo();
    expect(node.origin, const Offset(10, 0));
    history.undo();
    expect(node.origin, Offset.zero);
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isTrue);

    history.redo();
    expect(node.origin, const Offset(10, 0));
    history.redo();
    expect(node.origin, const Offset(20, 0));
    expect(history.canUndo, isTrue);
    expect(history.canRedo, isFalse);
  });

  test('a new change after undo discards the redo branch', () {
    move(10);
    history.undo();
    move(20);
    expect(history.canRedo, isFalse);
    history.undo();
    expect(node.origin, Offset.zero);
    history.redo();
    expect(node.origin, const Offset(20, 0));
  });

  test('empty and unchanged transactions preserve redo', () {
    move(10);
    history.undo();
    history.run('Empty', (_) {});
    move(0);
    expect(history.isActive, isFalse);
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isTrue);
    history.redo();
    expect(node.origin, const Offset(10, 0));
  });

  test('cancel restores mutations without adding history or clearing redo', () {
    move(10);
    history.undo();
    history.begin('Cancelled move');
    history.active.update(node, (node) => node.origin = const Offset(30, 0));
    history.cancel();
    expect(node.origin, Offset.zero);
    expect(history.isActive, isFalse);
    expect(history.canUndo, isFalse);
    expect(history.canRedo, isTrue);
    history.redo();
    expect(node.origin, const Offset(10, 0));
  });

  test('run rolls back partial changes and rethrows the original error', () {
    final error = Exception('Failed action');
    expect(
      () => history.run('Fail', (transaction) {
        transaction.update(node, (node) => node.origin = const Offset(30, 0));
        transaction.add(_rectangle());
        throw error;
      }),
      throwsA(same(error)),
    );
    expect(document.nodes, hasLength(1));
    expect(document.nodeById(node.id)!.origin, Offset.zero);
    expect(history.isActive, isFalse);
    expect(history.canUndo, isFalse);
    history.run('Next action', (transaction) => transaction.add(_rectangle()));
    expect(history.canUndo, isTrue);
  });

  test('nested begin and run leave the original transaction active', () {
    history.begin('Original');
    final original = history.active;
    expect(() => history.begin('Nested'), throwsStateError);
    expect(
      () => history.run('Nested', (_) => fail('Must not run')),
      throwsStateError,
    );
    expect(history.active, same(original));
    expect(original.isOpen, isTrue);
    history.cancel();
  });

  test(
    'undo and redo reject active transactions without consuming history',
    () {
      move(10);
      move(20);
      history.undo();
      history.begin('Pending');
      expect(history.undo, throwsStateError);
      expect(history.redo, throwsStateError);
      expect(node.origin, const Offset(10, 0));
      history.cancel();
      history.redo();
      expect(node.origin, const Offset(20, 0));
      history.undo();
      history.undo();
      expect(node.origin, Offset.zero);
    },
  );

  test('operations with no corresponding transaction or commit throw', () {
    expect(history.commit, throwsStateError);
    expect(history.cancel, throwsStateError);
    expect(history.undo, throwsStateError);
    expect(history.redo, throwsStateError);
    expect(history.isActive, isFalse);
  });

  test('begin and run forward the container and share one history stack', () {
    final child = _rectangle();
    final container = document.insert(
      Group(origin: Offset.zero, children: [child]),
    );
    history.begin('Move child', container: container);
    history.active.update(child, (node) => node.origin = const Offset(5, 0));
    history.commit();
    move(10);
    history.run('Move child again', (transaction) {
      transaction.update(child, (node) => node.origin = const Offset(15, 0));
    }, container: container);

    history.undo();
    expect(child.origin, const Offset(5, 0));
    history.undo();
    expect(node.origin, Offset.zero);
    history.undo();
    expect(child.origin, Offset.zero);
    history.redo();
    history.redo();
    history.redo();
    expect(child.origin, const Offset(15, 0));
    expect(node.origin, const Offset(10, 0));
  });
}

Feature _rectangle() => Feature(
  origin: Offset.zero,
  size: const Size(100, 80),
  kind: const FeatureKindRectangle(),
);
