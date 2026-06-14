import 'dart:async';

import 'package:squiggle_flutter/models/document.dart';

class DocumentRepository {
  DocumentRepository({required this.document});

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
