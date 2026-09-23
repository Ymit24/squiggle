import 'dart:ui';

import 'package:squiggle_flutter/models/node.dart';
import 'package:data_models/data_models.dart' as data;

import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/node_id.dart';
import 'package:squiggle_flutter/models/group.dart';

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
  final Map<Node, Rect> _boundsBeforeEdit = {};
  int _geometryEditDepth = 0;

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

  void editGeometry(Node node, void Function() change) {
    void capture(Node candidate) {
      _boundsBeforeEdit.putIfAbsent(candidate, candidate.globalBounds);
    }

    capture(node);
    NodeContainer? parent = node.parent;
    while (parent is Node) {
      final parentNode = parent as Node;
      capture(parentNode);
      parent = parentNode.parent;
    }
    void captureDescendants(Node current) {
      if (current is Group) {
        for (final child in current.children) {
          capture(child);
          captureDescendants(child);
        }
      }
    }

    captureDescendants(node);
    _geometryEditDepth++;
    try {
      change();
    } finally {
      _geometryEditDepth--;
      if (_geometryEditDepth == 0) {
        final changes = Map<Node, Rect>.of(_boundsBeforeEdit);
        _boundsBeforeEdit.clear();
        for (final entry in changes.entries) {
          if (identical(entry.key.document, this) &&
              entry.key.globalBounds() != entry.value) {
            notifyBoundFeatures(entry.key);
          }
        }
      }
    }
  }

  void notifyBoundFeatures(Node target) {
    for (final id in target.boundFeatureIds.toList()) {
      final feature = featureById(id);
      if (feature?.kind case BindCapable kind) {
        kind.onBoundNodeBoundsUpdate(feature!, target);
      }
    }
  }

  void setFeatureBinding(
    Feature feature, {
    required bool start,
    NodeBinding? binding,
  }) {
    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) {
      throw ArgumentError.value(feature, 'feature', 'Feature cannot bind');
    }
    final previous = start ? kind.startBinding : kind.endBinding;
    if (binding != null && nodeById(binding.targetId) == null) {
      throw StateError('Binding target does not exist');
    }
    if (binding?.targetId == feature.id) {
      throw StateError('A feature cannot bind to itself');
    }
    if (binding != null && _wouldCycle(feature, nodeById(binding.targetId)!)) {
      throw StateError('Binding would create a cycle');
    }
    if (start) {
      kind.startBinding = binding;
    } else {
      kind.endBinding = binding;
    }
    if (previous != null &&
        !kind.bindings.any((item) => item.targetId == previous.targetId)) {
      nodeById(previous.targetId)?.removeBoundFeature(feature.id);
    }
    if (binding != null) {
      nodeById(binding.targetId)?.addBoundFeature(feature.id);
    }
  }

  void rebuildBindings() {
    for (final node in _nodesById.values) {
      node.clearBoundFeatures();
    }
    for (final node in _nodesById.values) {
      if (node is Feature && node.kind is BindCapable) {
        final kind = node.kind as BindCapable;
        for (final binding in kind.bindings) {
          final target = nodeById(binding.targetId);
          if (target != null && !_wouldCycle(node, target)) {
            target.addBoundFeature(node.id);
          }
        }
      }
    }
    for (final node in _nodesById.values.toList()) {
      if (node.boundFeatureIds.isNotEmpty) notifyBoundFeatures(node);
    }
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

  Node? bindingTargetAt(Offset worldPoint, {required Feature source}) {
    Node? search(Node node) {
      if (node is Group) {
        for (final child in node.children.reversed) {
          final found = search(child);
          if (found != null) return found;
        }
      }
      if (identical(node, source) || _wouldCycle(source, node)) return null;
      final localPoint =
          worldPoint - (node.parent?.globalOrigin ?? Offset.zero);
      return node.hitTest(localPoint) ? node : null;
    }

    for (final node in _rootNodes.reversed) {
      final found = search(node);
      if (found != null) return found;
    }
    return null;
  }

  bool _wouldCycle(Feature source, Node target) {
    final seen = <NodeId>{};
    bool visit(Node node) {
      if (identical(node, source)) return true;
      if (!seen.add(node.id)) return false;
      if (node is Group) {
        for (final child in node.children) {
          if (visit(child)) return true;
        }
      }
      if (node is Feature && node.kind is BindCapable) {
        final kind = node.kind as BindCapable;
        for (final binding in kind.bindings) {
          final next = nodeById(binding.targetId);
          if (next != null && visit(next)) return true;
        }
      }
      return false;
    }

    return visit(target);
  }

  /// Root nodes whose bounds overlap [worldBounds].
  Iterable<Node> nodesInBounds(Rect worldBounds) =>
      _rootNodes.where((node) => node.localBounds().overlaps(worldBounds));

  /// Adds [feature], assigning an id when it has [noId].
  ///
  /// Returns the added feature (which may now carry an assigned id).
  Node addNode(Node feature) {
    final added = insert(feature);
    rebuildBindings();
    return added;
  }

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
      node.clearBoundFeatures();
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
      insert(node);
    }
    rebuildBindings();
  }

  // TODO: Change this to return bool
  void removeFeature(NodeId id) {
    removeAll([id]);
    rebuildBindings();
  }

  void removeFeatures(Iterable<NodeId> ids) {
    removeAll(ids);
    rebuildBindings();
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
