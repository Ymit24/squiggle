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

  @override
  final String label;

  final Map<NodeId, data.Node?> _before = {};
  List<NodeId>? _orderBefore;
  bool _isOpen = true;
  NodeId? get _containerId => container is Node ? (container as Node).id : null;

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
