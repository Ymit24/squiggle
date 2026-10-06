import 'package:squiggle_flutter/models/document.dart';

/// An immutable, replayable document change.
abstract interface class Commit {
  String get label;
  int get affectedNodeCount;
  bool get changesOrder;

  void undo(Document document);
  void redo(Document document);
}
