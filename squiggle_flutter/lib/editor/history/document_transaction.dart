import 'package:collection/collection.dart';
import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/editor/history/commit.dart';
import 'package:squiggle_flutter/editor/history/document_commit.dart';
import 'package:squiggle_flutter/editor/history/replay.dart';
import 'package:squiggle_flutter/editor/history/transaction.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// Snapshots affected immediate children (including their subtrees) in one
/// container. Group/ungroup within that scope; transfers between existing
/// containers require separate edits. Do not mutate other containers directly.
final class DocumentTransaction implements Transaction {
  /// Opens an edit scoped to [container], or to [document] when omitted.
  ///
  /// Throws an [ArgumentError] if [container] does not belong to [document].
  DocumentTransaction({
    required this.document,
    required this.label,
    NodeContainer? container,
  }) : container = container ?? document {
    if (!identical(this.container.document, document)) {
      throw ArgumentError('The container must belong to the document');
    }
  }

  /// Document whose nodes this transaction edits.
  final Document document;

  /// Container whose direct children this transaction may edit.
  final NodeContainer container;

  /// Human-readable label associated with this edit.
  @override
  final String label;

  final Map<NodeId, data.Node?> _before = {};
  List<NodeId>? _orderBefore;
  bool _isOpen = true;
  NodeId? get _containerId => container is Node ? (container as Node).id : null;

  /// Whether this transaction is still open.
  @override
  bool get isOpen => _isOpen;

  /// Saves each direct child in [nodes] before its first mutation.
  ///
  /// Throws an [ArgumentError] if any node is not a direct child of [container].
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

  /// Saves [node], then applies [change] to it.
  @override
  void update<T extends Node>(T node, void Function(T node) change) {
    watch([node]);
    change(node);
  }

  /// Adds [node] to the scoped container at [index], if supplied.
  @override
  T add<T extends Node>(T node, {int? index}) {
    _ensureOpen();
    _watchOrder();
    container.insert(node, index: index);
    _before.putIfAbsent(node.id, () => null);
    return node;
  }

  /// Removes any listed IDs that currently identify direct children.
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

  /// Reorders the container's direct children to match [ids].
  @override
  void reorder(Iterable<NodeId> ids) {
    _ensureOpen();
    _watchOrder();
    container.reorder(ids);
  }

  /// Closes this transaction and returns its change, or null if it was a no-op.
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

    final orderAfter = _orderBefore == null ? null : _captureOrder();
    final orderChanged =
        _orderBefore != null &&
        !const ListEquality<NodeId>().equals(_orderBefore, orderAfter);
    _isOpen = false;
    if (before.isEmpty && !orderChanged) return null;

    return DocumentCommit.fromStates(
      label: label,
      containerId: _containerId,
      before: before,
      after: after,
      orderBefore: orderChanged ? _orderBefore : null,
      orderAfter: orderChanged ? orderAfter : null,
    );
  }

  /// Restores the captured state and closes this transaction.
  @override
  void cancel() {
    _ensureOpen();
    applyDocumentState(container, states: _before, order: _orderBefore);
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
