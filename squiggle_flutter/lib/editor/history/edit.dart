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
  T add<T extends Node>(T node, {int? index});

  /// Removes nodes as part of this edit.
  void removeAll(Iterable<NodeId> ids);

  /// Reorders the scoped container's immediate children.
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

/// Snapshots affected immediate children (including their subtrees) in one
/// container. Group/ungroup within that scope; transfers between existing
/// containers require separate edits. Do not mutate other containers directly.
final class DocumentEdit implements Edit {
  DocumentEdit({
    required this.document,
    required this.label,
    NodeContainer? container,
  }) : container = container ?? document {
    if (!identical(this.container.document, document)) {
      throw ArgumentError('The container must belong to the document');
    }
  }

  final Document document;
  final NodeContainer container;
  NodeId? get _containerId => container is Node ? (container as Node).id : null;

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
      if (!identical(container.childById(node.id), node)) {
        throw ArgumentError.value(node, 'nodes', 'Node is not a direct child');
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
  T add<T extends Node>(T node, {int? index}) {
    _ensureOpen();
    _watchOrder();
    container.insert(node, index: index);
    _before.putIfAbsent(node.id, () => null);
    return node;
  }

  @override
  void removeAll(Iterable<NodeId> ids) {
    _ensureOpen();
    final nodes = <Node>[];
    for (final id in ids) {
      final node = container.childById(id);
      if (node != null) nodes.add(node);
    }
    if (nodes.isEmpty) return;
    _watchOrder();
    watch(nodes);
    container.removeAll(nodes.map((node) => node.id));
  }

  @override
  void reorder(Iterable<NodeId> ids) {
    _ensureOpen();
    _watchOrder();
    container.reorder(ids);
  }

  @override
  EditChange? commit() {
    _ensureOpen();
    final before = <NodeId, data.Node?>{};
    final after = <NodeId, data.Node?>{};
    for (final entry in _before.entries) {
      final state = container.childById(entry.key)?.toDataModel();
      if (entry.value != state) {
        before[entry.key] = entry.value;
        after[entry.key] = state;
      }
    }

    final orderAfter = _orderBefore == null
        ? null
        : List<NodeId>.unmodifiable(container.children.map((node) => node.id));
    final orderChanged =
        _orderBefore != null &&
        !const ListEquality<NodeId>().equals(_orderBefore, orderAfter);
    _isOpen = false;
    if (before.isEmpty && !orderChanged) return null;

    return DocumentEditChange._(
      label: label,
      containerId: _containerId,
      before: before,
      after: after,
      orderBefore: orderChanged ? _orderBefore : null,
      orderAfter: orderChanged ? orderAfter : null,
    );
  }

  @override
  void cancel() {
    _ensureOpen();
    _apply(container, states: _before, order: _orderBefore);
    _isOpen = false;
  }

  void _watchOrder() {
    _orderBefore ??= List<NodeId>.unmodifiable(
      container.children.map((node) => node.id),
    );
  }

  void _ensureOpen() {
    if (!_isOpen) throw StateError('Edit is already closed');
  }
}

final class DocumentEditChange implements EditChange {
  DocumentEditChange._({
    required this.label,
    required this.containerId,
    required Map<NodeId, data.Node?> before,
    required Map<NodeId, data.Node?> after,
    required this._orderBefore,
    required this._orderAfter,
  }) : _before = Map.unmodifiable(before),
       _after = Map.unmodifiable(after),
       assert((_orderBefore == null) == (_orderAfter == null));

  @override
  final String label;

  /// Null identifies the document; group instances are resolved again on replay.
  final NodeId? containerId;
  final Map<NodeId, data.Node?> _before;
  final Map<NodeId, data.Node?> _after;
  final List<NodeId>? _orderBefore;
  final List<NodeId>? _orderAfter;

  @override
  int get affectedNodeCount => _before.length;

  @override
  bool get changesOrder => _orderBefore != null;

  @override
  void undo(Document document) =>
      _apply(_resolve(document), states: _before, order: _orderBefore);

  @override
  void redo(Document document) =>
      _apply(_resolve(document), states: _after, order: _orderAfter);

  NodeContainer _resolve(Document document) {
    if (containerId == null) return document;
    final node = document.nodeById(containerId!);
    if (node is NodeContainer) return node as NodeContainer;
    throw StateError('Edit container no longer exists');
  }
}

/// Applies one saved side. Structural replay detaches outgoing subtrees first
/// so grouping/ungrouping can reuse descendant IDs without index collisions.
void _apply(
  NodeContainer container, {
  required Map<NodeId, data.Node?> states,
  required List<NodeId>? order,
}) {
  if (order == null) {
    for (final entry in states.entries) {
      if (entry.value != null) {
        container.childById(entry.key)!.restoreFromDataModel(entry.value!);
      }
    }
    return;
  }
  final restored = <NodeId, Node>{
    for (final entry in states.entries)
      if (entry.value != null) entry.key: Node.fromDataModel(entry.value!),
  };
  container.removeAll(states.keys);
  for (final node in restored.values) {
    container.insert(node);
  }
  container.reorder(order);
}
