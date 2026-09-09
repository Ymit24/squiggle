part of 'node.dart';

/// An ordered collection of immediate children. Mutations maintain ownership
/// and the owning document's global index. Detached subtrees retain their IDs.
abstract mixin class NodeContainer {
  final List<Node> _children = [];
  late final List<Node> children = UnmodifiableListView(_children);

  Document? get document;

  /// Finds a direct child; use Document.nodeById for global lookup.
  Node? childById(NodeId id) {
    final owner = document;
    if (owner != null) {
      final node = owner.nodeById(id);
      return identical(node?.parent, this) ? node : null;
    }
    for (final child in _children) {
      if (child.id == id) return child;
    }
    return null;
  }

  T insert<T extends Node>(T node, {int? index}) {
    final position = index ?? _children.length;
    RangeError.checkValueInInterval(position, 0, _children.length, 'index');
    if (node.parent != null) {
      throw StateError('Detach the node before inserting');
    }
    NodeContainer? ancestor = this;
    while (ancestor is Node) {
      if (identical(ancestor, node)) {
        throw StateError('A node cannot own itself');
      }
      ancestor = (ancestor as Node).parent;
    }
    document?.registerSubtree(node);
    _children.insert(position, node);
    node._parent = this;
    return node;
  }

  void removeAll(Iterable<NodeId> ids) {
    final removed = ids.toSet();
    if (removed.isEmpty) return;
    final owner = document;
    _children.removeWhere((node) {
      if (!removed.contains(node.id)) return false;
      owner?.unregisterSubtree(node);
      node._parent = null;
      return true;
    });
  }

  void reorder(Iterable<NodeId> ids) {
    final order = ids.toList();
    final byId = {for (final child in _children) child.id: child};
    if (order.length != _children.length ||
        order.toSet().length != order.length ||
        !order.every(byId.containsKey)) {
      throw ArgumentError('Order must contain every child exactly once');
    }
    _children
      ..clear()
      ..addAll(order.map((id) => byId[id]!));
  }
}
