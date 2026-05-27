import 'dart:ui';

import 'feature.dart';
import 'feature_id.dart';

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
      if (features[i].bounds().contains(worldPoint)) {
        return features[i];
      }
    }
    return null;
  }

  void executeCommand(Command command) {
    undoStack.add(command.clone());
    redoStack.clear();
    switch (command) {
      case AddFeatureCommand(:final feature):
        if (feature.id == noId) {
          feature.id = generateId();
        }
        features.add(feature);
      case RemoveFeaturesCommand(:final ids):
        for (final id in ids) {
          final index = featureIndexById(id);
          if (index != null) {
            features.removeAt(index);
          }
        }
      case MoveFeatureCommand(:final id, :final origin):
        featureById(id)?.moveTo(origin);
    }
  }
}

sealed class Command {
  const Command();

  Command clone();
}

final class AddFeatureCommand extends Command {
  const AddFeatureCommand(this.feature);

  final Feature feature;

  @override
  Command clone() => AddFeatureCommand(feature.copyWith());
}

final class RemoveFeaturesCommand extends Command {
  const RemoveFeaturesCommand(this.ids);

  final List<FeatureId> ids;

  @override
  Command clone() => RemoveFeaturesCommand(List.of(ids));
}

final class MoveFeatureCommand extends Command {
  const MoveFeatureCommand(this.id, this.origin);

  final FeatureId id;
  final Offset origin;

  @override
  Command clone() => MoveFeatureCommand(id, origin);
}

