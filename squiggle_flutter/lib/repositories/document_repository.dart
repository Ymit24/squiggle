import 'dart:async';

import 'package:squiggle_flutter/models/document.dart';

class DocumentRepository {
  DocumentRepository({required this.document});

  final Document document;

  final StreamController<void> _changesController =
      StreamController<void>.broadcast();

  Stream<void> get changesStream => _changesController.stream;

  bool get canUndo => document.canUndo;

  bool get canRedo => document.canRedo;

  void executeCommand(Command command) {
    document.executeCommand(command);
    _changesController.add(null);
  }

  void notifyChanged() {
    _changesController.add(null);
  }

  void undo() {
    if (!canUndo) return;
    document.undo();
    _changesController.add(null);
  }

  void redo() {
    if (!canRedo) return;
    document.redo();
    _changesController.add(null);
  }

  void replaceDocument(Document document) {
    this.document.features
      ..clear()
      ..addAll(document.features);
    this.document.nextId = document.nextId;
    this.document.undoStack.clear();
    this.document.redoStack.clear();
    _changesController.add(null);
  }

  void dispose() {
    _changesController.close();
  }
}
