import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:data_models/data_models.dart' as data;

import 'feature.dart';
import 'feature_id.dart';

/// World model: editable collection of features in world space.
///
/// `Document` is a pure data model plus the source of truth for mutations. It
/// exposes no command or history concept; changes are announced to observers
/// via [ChangeNotifier]. Undo/redo bookkeeping lives in the command layer.
class Document extends ChangeNotifier {
  Document({FeatureId? nextId}) : _nextId = nextId ?? FeatureId.newId(1);

  factory Document.fromFeatures(List<Feature> features) {
    final doc = Document();
    for (final feature in features) {
      doc.addFeature(feature);
    }
    return doc;
  }

  factory Document.fromDataModel(data.Document raw) {
    final document = Document();
    document.addFeatures([
      for (final node in raw.nodes)
        switch (node) {
          data.Feature() => Feature.fromDataModel(node),
          data.Group() => throw FormatException(
            'Groups are not supported by the current Document model',
          ),
          _ => throw FormatException(
            'Unsupported node type: ${node.runtimeType}',
          ),
        },
    ]);
    return document;
  }

  data.Document toDataModel() {
    return data.Document(
      nodes: _features.map((feature) => feature.toDataModel()).toList(),
    );
  }

  List<Feature> get _features => nodes.whereType<Feature>().toList();

  final List<Node> _nodes = [];

  List<Node> get nodes => _nodes;

  /// Live view of the features in document order.
  List<Feature> get features => List.unmodifiable(_features);

  FeatureId _nextId;
  int get nextId => _nextId.value;

  FeatureId generateId() {
    final id = _nextId;
    _nextId = FeatureId.newId(_nextId.value + 1);
    return id;
  }

  void notifyChanged() => notifyListeners();

  Feature? featureById(FeatureId id) {
    for (final feature in _features) {
      if (feature.id == id) return feature;
    }
    return null;
  }

  int? _featureIndexById(FeatureId id) {
    for (var i = 0; i < _features.length; i++) {
      if (_features[i].id == id) return i;
    }
    return null;
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
  Feature addFeature(Feature feature) {
    if (feature.id == noId) {
      feature.id = generateId();
    } else if (feature.id.value >= _nextId.value) {
      _nextId = FeatureId.newId(feature.id.value + 1);
    }
    _nodes.add(feature);
    notifyListeners();
    return feature;
  }

  /// Adds multiple features in one change notification.
  void addFeatures(Iterable<Feature> features) {
    for (final feature in features) {
      addFeature(feature);
    }
    notifyListeners();
  }

  // TODO: Change this to return bool
  void removeFeature(FeatureId id) {
    final index = _nodes.indexWhere((node) => node.id == id);
    if (index == -1) return;

    _nodes.removeAt(index);
    notifyListeners();
  }

  void removeFeatures(Iterable<FeatureId> ids) {
    for (final id in ids) {
      removeFeature(id);
    }
    notifyListeners();
  }

  /// Replaces this document's contents with [other], notifying once.
  void replaceFrom(Document other) {
    _features
      ..clear()
      ..addAll(other._features.map((feature) => feature.copyWith()));
    _nextId = other._nextId;
    notifyListeners();
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
