import 'package:collection/collection.dart';
import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// One in-progress document edit.
abstract interface class Transaction {
  String get label;
  bool get isOpen;

  /// Captures each existing node before its first mutation.
  void watch(Iterable<Node> nodes);

  /// Captures [node], then applies [change].
  void update<T extends Node>(T node, void Function(T node) change);

  /// Adds a node as part of this edit.
  T add<T extends Node>(T node, {int? index});

  /// Removes nodes and detaches surviving sources from the deleted targets.
  /// Use [preserveBindings] for temporary removal while reparenting nodes.
  void removeAll(Iterable<NodeId> ids, {bool preserveBindings = false});

  /// Reorders the scoped container's immediate children.
  void reorder(Iterable<NodeId> ids);

  /// Closes the edit and returns its change, or null when nothing changed.
  Commit? commit();

  /// Restores the document to its state before this edit.
  void cancel();
}

/// An immutable, replayable document change.
abstract interface class Commit {
  String get label;
  int get affectedNodeCount;
  bool get changesOrder;

  void undo(Document document);
  void redo(Document document);
}

/// Snapshots affected immediate children (including their subtrees) in one
/// container. Group/ungroup within that scope; transfers between existing
/// containers require separate edits. Do not mutate other containers directly.
/// Deletion also captures binding sources in other containers by their IDs.
final class DocumentTransaction implements Transaction {
  DocumentTransaction({
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
  final Map<NodeId, data.Feature> _bindingSourcesBefore = {};
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
  void removeAll(Iterable<NodeId> ids, {bool preserveBindings = false}) {
    _ensureOpen();
    final nodes = <Node>[];
    for (final id in ids) {
      final node = container.childById(id);
      if (node != null) nodes.add(node);
    }
    if (nodes.isEmpty) return;
    _watchOrder();
    watch(nodes);
    if (!preserveBindings) _notifyBindingSources(nodes);
    container.removeAll(nodes.map((node) => node.id));
  }

  void _notifyBindingSources(List<Node> removedNodes) {
    final deletedIds = <NodeId>{};
    void collect(Node node) {
      deletedIds.add(node.id);
      if (node is NodeContainer) {
        for (final child in (node as NodeContainer).children) {
          collect(child);
        }
      }
    }

    removedNodes.forEach(collect);

    final affected = <(Feature, BindingSourceCapable, Set<NodeId>)>[];
    for (final feature in document.allNodes.whereType<Feature>()) {
      final kind = feature.kind;
      if (deletedIds.contains(feature.id) || kind is! BindingSourceCapable) {
        continue;
      }
      final targetIds = kind.bindings
          .map((binding) => binding.targetId)
          .where(deletedIds.contains)
          .toSet();
      if (targetIds.isNotEmpty) affected.add((feature, kind, targetIds));
    }
    for (final (feature, _, _) in affected) {
      _watchBindingSource(feature);
    }
    for (final (feature, kind, targetIds) in affected) {
      kind.onBindingTargetsDeleted(feature, Set.unmodifiable(targetIds));
    }
  }

  void _watchBindingSource(Feature source) {
    if (identical(source.parent, container)) {
      watch([source]);
      return;
    }
    // A previously captured ancestor already covers this source's mutations.
    Node ancestor = source;
    while (true) {
      if (identical(ancestor.parent, container) &&
          _before.containsKey(ancestor.id)) {
        return;
      }
      final parent = ancestor.parent;
      if (parent is! Node) break;
      ancestor = parent as Node;
    }
    _bindingSourcesBefore.putIfAbsent(source.id, source.toDataModel);
  }

  @override
  void reorder(Iterable<NodeId> ids) {
    _ensureOpen();
    _watchOrder();
    container.reorder(ids);
  }

  @override
  Commit? commit() {
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

    final bindingSourcesBefore = <NodeId, data.Feature?>{};
    final bindingSourcesAfter = <NodeId, data.Feature?>{};
    for (final entry in _bindingSourcesBefore.entries) {
      final state = document.featureById(entry.key)?.toDataModel();
      if (entry.value != state) {
        bindingSourcesBefore[entry.key] = entry.value;
        bindingSourcesAfter[entry.key] = state;
      }
    }

    final orderAfter = _orderBefore == null ? null : _captureOrder();
    final orderChanged =
        _orderBefore != null &&
        !const ListEquality<NodeId>().equals(_orderBefore, orderAfter);
    _isOpen = false;
    if (before.isEmpty && bindingSourcesBefore.isEmpty && !orderChanged) {
      return null;
    }

    return DocumentCommit._(
      label: label,
      containerId: _containerId,
      before: before,
      after: after,
      bindingSourcesBefore: bindingSourcesBefore,
      bindingSourcesAfter: bindingSourcesAfter,
      orderBefore: orderChanged ? _orderBefore : null,
      orderAfter: orderChanged ? orderAfter : null,
    );
  }

  @override
  void cancel() {
    _ensureOpen();
    _apply(container, states: _before, order: _orderBefore);
    _restoreBindingSources(document, _bindingSourcesBefore);
    _isOpen = false;
  }

  void _watchOrder() {
    _orderBefore ??= _captureOrder();
  }

  List<NodeId> _captureOrder() =>
      List<NodeId>.unmodifiable(container.children.map((node) => node.id));

  void _ensureOpen() {
    if (!_isOpen) throw StateError('Edit is already closed');
  }
}

final class DocumentCommit implements Commit {
  DocumentCommit._({
    required this.label,
    required this.containerId,
    required Map<NodeId, data.Node?> before,
    required Map<NodeId, data.Node?> after,
    required Map<NodeId, data.Feature?> bindingSourcesBefore,
    required Map<NodeId, data.Feature?> bindingSourcesAfter,
    required this._orderBefore,
    required this._orderAfter,
  }) : _before = Map.unmodifiable(before),
       _after = Map.unmodifiable(after),
       _bindingSourcesBefore = Map.unmodifiable(bindingSourcesBefore),
       _bindingSourcesAfter = Map.unmodifiable(bindingSourcesAfter),
       assert((_orderBefore == null) == (_orderAfter == null));

  @override
  final String label;

  /// Null identifies the document; group instances are resolved again on replay.
  final NodeId? containerId;
  final Map<NodeId, data.Node?> _before;
  final Map<NodeId, data.Node?> _after;
  final Map<NodeId, data.Feature?> _bindingSourcesBefore;
  final Map<NodeId, data.Feature?> _bindingSourcesAfter;
  final List<NodeId>? _orderBefore;
  final List<NodeId>? _orderAfter;

  @override
  int get affectedNodeCount =>
      {..._before.keys, ..._bindingSourcesBefore.keys}.length;

  @override
  bool get changesOrder => _orderBefore != null;

  @override
  void undo(Document document) {
    _apply(_resolve(document), states: _before, order: _orderBefore);
    _restoreBindingSources(document, _bindingSourcesBefore);
  }

  @override
  void redo(Document document) {
    _apply(_resolve(document), states: _after, order: _orderAfter);
    _restoreBindingSources(document, _bindingSourcesAfter);
  }

  NodeContainer _resolve(Document document) {
    if (containerId == null) return document;
    final node = document.nodeById(containerId!);
    if (node is NodeContainer) return node as NodeContainer;
    throw StateError('Edit container no longer exists');
  }
}

void _restoreBindingSources(
  Document document,
  Map<NodeId, data.Feature?> states,
) {
  for (final entry in states.entries) {
    final source = document.featureById(entry.key);
    if (source != null && entry.value != null) {
      source.restoreFromDataModel(entry.value!);
    }
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
    _restoreInPlace(container, states);
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

void _restoreInPlace(NodeContainer container, Map<NodeId, data.Node?> states) {
  for (final entry in states.entries) {
    if (entry.value != null) {
      container.childById(entry.key)!.restoreFromDataModel(entry.value!);
    }
  }
}
