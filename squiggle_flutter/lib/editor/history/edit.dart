import 'package:collection/collection.dart';
import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// One in-progress document edit.
abstract interface class Edit {
  String get label;
  bool get isOpen;

  /// Captures each existing node before its first mutation.
  void watch(Iterable<Node> nodes);

  /// Captures [node], then applies [change].
  void update<T extends Node>(T node, void Function(T node) change);

  /// Adds a node as part of this edit.
  T add<T extends Node>(T node);

  /// Removes nodes as part of this edit.
  void removeAll(Iterable<NodeId> ids);

  /// Reorders every node in the document.
  void reorder(Iterable<NodeId> ids);

  /// Closes the edit and returns its change, or null when nothing changed.
  EditChange? commit();

  /// Restores the document to its state before this edit.
  void cancel();
}

/// An immutable, replayable document change.
abstract interface class EditChange {
  String get label;
  int get affectedNodeCount;
  bool get changesOrder;

  void undo(Document document);
  void redo(Document document);
}

/// An edit that snapshots only affected nodes.
final class DocumentEdit implements Edit {
  DocumentEdit({required this.document, required this.label});

  final Document document;

  @override
  final String label;

  final Map<NodeId, data.Node?> _before = {};
  List<NodeId>? _orderBefore;
  bool _isOpen = true;

  @override
  bool get isOpen => _isOpen;

  @override
  void watch(Iterable<Node> nodes) {
    _ensureOpen();
    for (final node in nodes) {
      if (!identical(document.nodeById(node.id), node)) {
        throw ArgumentError.value(node, 'nodes', 'Node is not in the document');
      }
      _before.putIfAbsent(node.id, node.toDataModel);
    }
  }

  @override
  void update<T extends Node>(T node, void Function(T node) change) {
    watch([node]);
    change(node);
  }

  @override
  T add<T extends Node>(T node) {
    _ensureOpen();
    _watchOrder();
    document.addNode(node);
    final added = node;
    _before.putIfAbsent(added.id, () => null);
    return added;
  }

  @override
  void removeAll(Iterable<NodeId> ids) {
    _ensureOpen();
    final nodes = <Node>[];
    for (final id in ids) {
      final node = document.nodeById(id);
      if (node != null) nodes.add(node);
    }
    if (nodes.isEmpty) return;
    _watchOrder();
    watch(nodes);
    document.removeFeatures(nodes.map((node) => node.id));
  }

  @override
  void reorder(Iterable<NodeId> ids) {
    _ensureOpen();
    _watchOrder();
    document.reorderNodes(ids);
  }

  @override
  EditChange? commit() {
    _ensureOpen();
    _isOpen = false;

    final changes = <NodeId, _NodeChange>{};
    for (final entry in _before.entries) {
      final node = document.nodeById(entry.key);
      final after = node?.toDataModel();
      if (!_sameNode(entry.value, after)) {
        changes[entry.key] = _NodeChange(entry.value, after);
      }
    }

    final orderAfter = _orderBefore == null
        ? null
        : List<NodeId>.unmodifiable(document.nodes.map((node) => node.id));
    final orderChanged =
        _orderBefore != null &&
        !const ListEquality<NodeId>().equals(_orderBefore, orderAfter);
    if (changes.isEmpty && !orderChanged) return null;

    return DocumentEditChange._(
      label: label,
      changes: changes,
      orderBefore: orderChanged ? _orderBefore : null,
      orderAfter: orderChanged ? orderAfter : null,
    );
  }

  @override
  void cancel() {
    _ensureOpen();
    _isOpen = false;
    final orderAfter = _orderBefore == null
        ? null
        : List<NodeId>.unmodifiable(document.nodes.map((node) => node.id));
    DocumentEditChange._(
      label: label,
      changes: {
        for (final entry in _before.entries)
          entry.key: _NodeChange(entry.value, null),
      },
      orderBefore: _orderBefore,
      orderAfter: orderAfter,
    ).undo(document);
  }

  void _watchOrder() {
    _orderBefore ??= List<NodeId>.unmodifiable(
      document.nodes.map((node) => node.id),
    );
  }

  void _ensureOpen() {
    if (!_isOpen) throw StateError('Edit is already closed');
  }
}

final class DocumentEditChange implements EditChange {
  DocumentEditChange._({
    required this.label,
    required Map<NodeId, _NodeChange> changes,
    required this._orderBefore,
    required this._orderAfter,
  }) : _changes = Map.unmodifiable(changes),
       assert((_orderBefore == null) == (_orderAfter == null));

  @override
  final String label;

  final Map<NodeId, _NodeChange> _changes;
  final List<NodeId>? _orderBefore;
  final List<NodeId>? _orderAfter;

  @override
  int get affectedNodeCount => _changes.length;

  @override
  bool get changesOrder => _orderBefore != null;

  @override
  void undo(Document document) => _apply(document, useAfter: false);

  @override
  void redo(Document document) => _apply(document, useAfter: true);

  void _apply(Document document, {required bool useAfter}) {
    final removals = <NodeId>[];
    for (final entry in _changes.entries) {
      final state = useAfter ? entry.value.after : entry.value.before;
      final current = document.nodeById(entry.key);
      if (state == null) {
        if (current != null) removals.add(entry.key);
      } else if (current == null) {
        document.addNode(Node.fromDataModel(state));
      } else {
        current.restoreFromDataModel(state);
      }
    }
    document.removeFeatures(removals);

    final order = useAfter ? _orderAfter : _orderBefore;
    if (order != null) document.reorderNodes(order);
  }
}

final class _NodeChange {
  const _NodeChange(this.before, this.after);

  final data.Node? before;
  final data.Node? after;
}

bool _sameNode(data.Node? a, data.Node? b) {
  if (identical(a, b)) return true;
  if (a is data.Feature && b is data.Feature) {
    return a.id == b.id &&
        a.originX == b.originX &&
        a.originY == b.originY &&
        a.width == b.width &&
        a.height == b.height &&
        const DeepCollectionEquality().equals(a.content, b.content);
  }
  if (a is data.Group && b is data.Group) {
    return a.id == b.id &&
        a.originX == b.originX &&
        a.originY == b.originY &&
        _sameNodes(a.children, b.children);
  }
  return false;
}

bool _sameNodes(List<data.Node> a, List<data.Node> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (!_sameNode(a[i], b[i])) return false;
  }
  return true;
}
