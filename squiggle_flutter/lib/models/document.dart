import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:data_models/data_models.dart' as data;

import 'feature.dart';
import 'node_id.dart';

/// Editable document tree with document-wide node IDs.
///
/// Root nodes are stored in paint order. Descendants belong to their owning
/// node's child collection, whose order defines painting within that container.
/// ID lookup is independent of tree structure and sibling order.
///
/// Undo/redo bookkeeping lives in the editor's history layer.
class Document {
  Document({this.name = 'Untitled', NodeId? nextId})
    : _nextId = nextId ?? NodeId.newId(1);

  String name;

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
      nodes: _nodes.map((node) => node.toDataModel()).toList(),
    );
  }

  List<Feature> get _features => _nodes.whereType<Feature>().toList();

  /// Root nodes in paint order; descendants live in their owners' child lists.
  /// TODO: Rename to _rootNodes when the container API is introduced.
  final List<Node> _nodes = [];

  /// ID lookup index, carrying no parent or paint-order information.
  /// TODO: Index all descendants as well as roots as tree mutation support lands.
  final Map<NodeId, Node> _nodesById = {};

  List<Node> get nodes => List.unmodifiable(_nodes);

  /// Live view of the features in document order.
  List<Feature> get features => List.unmodifiable(_features);

  NodeId _nextId;
  int get nextId => _nextId.value;

  NodeId generateId() {
    final id = _nextId;
    _nextId = NodeId.newId(_nextId.value + 1);
    return id;
  }

  Node? nodeById(NodeId id) => _nodesById[id];

  Feature? featureById(NodeId id) {
    final node = _nodesById[id];
    return node is Feature ? node : null;
  }

  /// Top-most feature whose bounds contain [worldPoint], if any.
  Feature? featureAtPoint(Offset worldPoint) {
    for (var i = _features.length - 1; i >= 0; i--) {
      if (_features[i].hitTest(worldPoint)) {
        return _features[i];
      }
    }
    return null;
  }

  /// Adds [feature], assigning an id when it has [noId].
  ///
  /// Returns the added feature (which may now carry an assigned id).
  Node addNode(Node feature) {
    if (feature.id == noId) {
      feature.id = generateId();
    } else if (feature.id.value >= _nextId.value) {
      _nextId = NodeId.newId(feature.id.value + 1);
    }
    if (_nodesById.containsKey(feature.id)) {
      throw ArgumentError.value(feature.id, 'feature.id', 'Duplicate node id');
    }
    _nodes.add(feature);
    _nodesById[feature.id] = feature;

    return feature;
  }

  /// Adds multiple features
  void addNodes(Iterable<Node> nodes) {
    for (final node in nodes) {
      addNode(node);
    }
  }

  // TODO: Change this to return bool
  void removeFeature(NodeId id) {
    final node = _nodesById.remove(id);
    if (node == null) return;
    _nodes.remove(node);
  }

  void removeFeatures(Iterable<NodeId> ids) {
    final removedIds = ids.toSet();
    if (removedIds.isEmpty) return;
    _nodes.removeWhere((node) => removedIds.contains(node.id));
    for (final id in removedIds) {
      _nodesById.remove(id);
    }
  }

  /// Reorders all nodes without changing their contents.
  void reorderNodes(Iterable<NodeId> ids) {
    final order = ids.toList();
    if (order.length != _nodes.length || order.toSet().length != order.length) {
      throw ArgumentError('Order must contain every node id exactly once');
    }
    if (!order.every(_nodesById.containsKey)) {
      throw ArgumentError('Order contains an unknown node id');
    }
    _nodes
      ..clear()
      ..addAll(order.map((id) => _nodesById[id]!));
  }

  /// Replaces this document's contents with [other], notifying once.
  void replaceFrom(Document other) {
    _nodes
      ..clear()
      ..addAll(other._nodes.map((node) => node.copyWith()));
    _nodesById
      ..clear()
      ..addEntries(_nodes.map((node) => MapEntry(node.id, node)));
    _nextId = other._nextId;
    name = other.name;
  }

  void groupNodes(List<Node> nodes) {
    final groupOrigin = Node.boundsOfNodes(nodes).center;

    for (var child in nodes) {
      child.origin -= groupOrigin;
      removeFeature(child.id);
    }

    // final group = Group(origin: groupOrigin, children: nodes);
  }
}
