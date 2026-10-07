import 'package:squiggle_flutter/models/document.dart';

/// An immutable, replayable document change.
abstract interface class Commit {
  /// Human-readable label associated with this change.
  String get label;

  /// Number of direct nodes whose saved state differs across this change.
  int get affectedNodeCount;

  /// Whether replaying this change also changes the container's child order.
  bool get changesOrder;

  /// Restores the document to the state before this change.
  void undo(Document document);

  /// Applies this change to restore the state after it was committed.
  void redo(Document document);
}
