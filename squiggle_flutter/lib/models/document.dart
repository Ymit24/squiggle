import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/models/group.dart';
import 'package:squiggle_flutter/models/node.dart';

import 'feature.dart';
import 'feature_geometry.dart';
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

  final List<Feature> _features = [];

  /// Live view of the features in document order.
  List<Feature> get features => List.unmodifiable(_features);

  FeatureId _nextId;
  int get nextId => _nextId.value;

  FeatureId generateId() {
    final id = _nextId;
    _nextId = FeatureId.newId(_nextId.value + 1);
    return id;
  }

  Feature? featureById(FeatureId id) {
    for (final feature in _features) {
      if (feature.id == id) return feature;
    }
    return null;
  }

  int? featureIndexById(FeatureId id) {
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
    _features.add(feature);
    notifyListeners();
    return feature;
  }

  /// Adds multiple features in one change notification.
  void addFeatures(Iterable<Feature> features) {
    for (final feature in features) {
      if (feature.id == noId) {
        feature.id = generateId();
      } else if (feature.id.value >= _nextId.value) {
        _nextId = FeatureId.newId(feature.id.value + 1);
      }
      _features.add(feature);
    }
    notifyListeners();
  }

  void removeFeature(FeatureId id) {
    final index = featureIndexById(id);
    if (index == null) return;
    _features.removeAt(index);
    notifyListeners();
  }

  void removeFeatures(Iterable<FeatureId> ids) {
    var changed = false;
    for (final id in ids) {
      final index = featureIndexById(id);
      if (index != null) {
        _features.removeAt(index);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void moveFeature(FeatureId id, Offset origin) {
    final feature = featureById(id);
    if (feature == null) return;
    feature.moveTo(origin);
    notifyListeners();
  }

  void moveFeatures(Map<FeatureId, Offset> origins) {
    var changed = false;
    for (final entry in origins.entries) {
      final feature = featureById(entry.key);
      if (feature != null && feature.origin != entry.value) {
        feature.moveTo(entry.value);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void setFeatureBounds(FeatureId id, Rect bounds) {
    final feature = featureById(id);
    if (feature == null) return;
    feature.setBounds(bounds);
    notifyListeners();
  }

  void setFeatureKind(FeatureId id, FeatureKind kind, {Size? size}) {
    final feature = featureById(id);
    if (feature == null) return;
    if (size != null) feature.size = size;
    feature.kind = kind;
    notifyListeners();
  }

  /// Moves a polyline vertex to [worldPosition], re-normalizing origin and size.
  void setPolylinePoint(FeatureId id, int pointIndex, Offset worldPosition) {
    final feature = featureById(id);
    if (feature == null) return;

    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) return;

    final points = worldPoints(feature.origin, kind.localPoints);
    if (pointIndex < 0 || pointIndex >= points.length) return;

    points[pointIndex] = worldPosition;
    setPolylineGeometry(
      id,
      origin: points.first,
      localPoints: localPointsFromWorld(points, points.first),
    );
  }

  /// Replaces a polyline's origin and local points, re-normalizing its size.
  void setPolylineGeometry(
    FeatureId id, {
    required Offset origin,
    required List<Offset> localPoints,
  }) {
    final feature = featureById(id);
    if (feature == null) return;

    final kind = feature.kind;
    if (kind is! FeatureKindPolyline) return;

    feature.moveTo(origin);
    feature.kind = kind.copyWith(localPoints: List.of(localPoints));
    feature.size = feature.bounds().size;
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

    final group = Group(origin: groupOrigin, children: nodes);
  }
}
