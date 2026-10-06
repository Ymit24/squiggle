import 'package:data_models/data_models.dart' as data;
import 'package:squiggle_flutter/editor/history/commit.dart';
import 'package:squiggle_flutter/editor/history/replay.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';

final class DocumentCommit implements Commit {
  DocumentCommit.fromStates({
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
      applyDocumentState(_resolve(document), states: _before, order: _orderBefore);

  @override
  void redo(Document document) =>
      applyDocumentState(_resolve(document), states: _after, order: _orderAfter);

  NodeContainer _resolve(Document document) {
    if (containerId == null) return document;
    final node = document.nodeById(containerId!);
    if (node is NodeContainer) return node as NodeContainer;
    throw StateError('Edit container no longer exists');
  }
}
