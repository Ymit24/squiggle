import 'dart:async';

import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/feature.dart';

class DocumentRepository {
  DocumentRepository({Document? document})
    : document = document ?? Document();

  factory DocumentRepository.fromFeatures(List<Feature> features) {
    final repository = DocumentRepository();
    for (final feature in features) {
      repository.executeCommand(AddFeatureCommand(feature));
    }
    return repository;
  }

  final Document document;

  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  Stream<void> get changesStream => _changesController.stream;

  void executeCommand(Command command) {
    document.executeCommand(command);
    _changesController.add(null);
  }

  void dispose() {
    _changesController.close();
  }
}
