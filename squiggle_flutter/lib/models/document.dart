import 'dart:ui';

import 'package:squiggle_flutter/models/node.dart';
import 'package:data_models/data_models.dart' as data;

import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// Editable document tree with document-wide node IDs.
///
/// Root nodes are stored in paint order. Descendants belong to their owning
/// node's child collection, whose order defines painting within that container.
/// ID lookup is independent of tree structure and sibling order.
///
/// Undo/redo bookkeeping lives in the editor's history layer.
class Document extends NodeContainer {
  Document({this.name = 'Untitled', NodeId? nextId})
    : _nextId = nextId ?? NodeId.newId(1);

  String name;

  @override
  Document get document => this;

  factory Document.fromFeatures(List<Feature> features) {
    final doc = Document();
    for (final feature in features) {
      doc.addNode(feature);
    }
    return doc;
  }

  factory Document.fromDataModel(data.Document raw) {
    final document = Document(name: raw.name);
    document.addNodes(raw.nodes.map(Node.fromDataModel));
    return document;
  }

  data.Document toDataModel() {
    return data.Document(
      name: name,
      nodes: _rootNodes.map((node) => node.toDataModel()).toList(),
    );
  }

  /// Root nodes in paint order; descendants live in their owners' child lists.
  List<Node> get _rootNodes => children;

  /// ID lookup index, carrying no parent or paint-order information.
  final Map<NodeId, Node> _nodesById = {};

  List<Node> get nodes => _rootNodes;

  NodeId _nextId;
  int get nextId => _nextId.value;

  NodeId generateId() {
    final id = _nextId;
    _nextId = NodeId.newId(_nextId.value + 1);
    return id;
  }

  Node? nodeById(NodeId id) => _nodesById[id];

  /// Returns the node with [id], or throws if it is not in this document.
  Node requireNodeById(NodeId id) {
    return _nodesById[id] ??
        (throw StateError('Node with id ${id.value} does not exist'));
  }

  Feature? featureById(NodeId id) {
    final node = _nodesById[id];
    return node is Feature ? node : null;
  }

  /// Top-most feature whose bounds contain [worldPoint], if any.
  Node? nodeAtPoint(Offset worldPoint) {
    for (final node in _rootNodes.reversed) {
      if (node.hitTest(worldPoint)) {
        return node;
      }
    }
    return null;
  }

  /// Adds [feature], assigning an id when it has [noId].
  ///
  /// Returns the added feature (which may now carry an assigned id).
  Node addNode(Node feature) => insert(feature);

  /// Container bookkeeping: validate all IDs before registering a subtree.
  void registerSubtree(Node root) {
    final nodes = _subtree(root).toList();
    final ids = <NodeId>{};
    for (final node in nodes) {
      if (node.id == noId) continue;
      if (_nodesById.containsKey(node.id) || !ids.add(node.id)) {
        throw ArgumentError.value(node.id, 'id', 'Duplicate node id');
      }
    }
    for (final id in ids) {
      if (id.value >= nextId) _nextId = NodeId.newId(id.value + 1);
    }
    for (final node in nodes) {
      if (node.id == noId) node.id = generateId();
      _nodesById[node.id] = node;
    }
  }

  /// Container bookkeeping: descendants leave the index with their root.
  void unregisterSubtree(Node root) {
    for (final node in _subtree(root)) {
      _nodesById.remove(node.id);
    }
  }

  Iterable<Node> _subtree(Node node) sync* {
    yield node;
    if (node is NodeContainer) {
      for (final child in (node as NodeContainer).children) {
        yield* _subtree(child);
      }
    }
  }

  /// Adds multiple features
  void addNodes(Iterable<Node> nodes) {
    for (final node in nodes) {
      addNode(node);
    }
  }

  // TODO: Change this to return bool
  void removeFeature(NodeId id) {
    removeAll([id]);
  }

  void removeFeatures(Iterable<NodeId> ids) {
    removeAll(ids);
  }

  /// Reorders all nodes without changing their contents.
  void reorderNodes(Iterable<NodeId> ids) {
    reorder(ids);
  }

  /// Replaces this document's contents with a copy of [other].
  void replaceFrom(Document other) {
    final copies = other.nodes.map((node) => node.copyWith()).toList();
    final next = other._nextId;
    removeAll(nodes.map((node) => node.id));
    _nextId = next;
    addNodes(copies);
    name = other.name;
  }

  @override
  Offset get globalOrigin => Offset.zero;
}
