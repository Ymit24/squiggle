import 'dart:ui';

import 'commands/command.dart';
import 'feature.dart';
import 'feature_id.dart';

export 'commands/command.dart';

/// Editable collection of features with undo/redo command recording.
class Document {
  Document() : nextId = FeatureId.newId(1);

  factory Document.fromFeatures(List<Feature> features) {
    final doc = Document();
    for (final feature in features) {
      doc.executeCommand(AddFeatureCommand(feature));
    }
    return doc;
  }

  final List<Feature> features = [];
  FeatureId nextId;
  final List<Command> undoStack = [];
  final List<Command> redoStack = [];

  FeatureId generateId() {
    final id = nextId;
    nextId = FeatureId.newId(nextId.value + 1);
    return id;
  }

  Feature? featureById(FeatureId id) {
    for (final feature in features) {
      if (feature.id == id) return feature;
    }
    return null;
  }

  int? featureIndexById(FeatureId id) {
    for (var i = 0; i < features.length; i++) {
      if (features[i].id == id) return i;
    }
    return null;
  }

  /// Top-most feature whose bounds contain [worldPoint], if any.
  Feature? featureAtPoint(Offset worldPoint) {
    for (var i = features.length - 1; i >= 0; i--) {
      if (features[i].hitTest(worldPoint)) {
        return features[i];
      }
    }
    return null;
  }

  void executeCommand(Command command) {
    command.apply(this);
    undoStack.add(command.clone());
    redoStack.clear();
  }

  void undo() {
    if (undoStack.isEmpty) return;

    final command = undoStack.removeLast();
    command.undo(this);
    redoStack.add(command);
  }

  void redo() {
    if (redoStack.isEmpty) return;

    final command = redoStack.removeLast();
    command.apply(this);
    undoStack.add(command);
  }
}
