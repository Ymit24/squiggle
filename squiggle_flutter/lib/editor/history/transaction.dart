import 'package:squiggle_flutter/editor/history/commit.dart';
import 'package:squiggle_flutter/models/node.dart';
import 'package:squiggle_flutter/models/node_id.dart';

/// One in-progress document edit.
abstract interface class Transaction {
  /// Human-readable label associated with this edit.
  String get label;

  /// Whether this transaction can still be changed, committed, or canceled.
  bool get isOpen;

  /// Captures each existing node before its first mutation.
  void watch(Iterable<Node> nodes);

  /// Captures [node], then applies [change].
  void update<T extends Node>(T node, void Function(T node) change);

  /// Adds a node as part of this edit.
  T add<T extends Node>(T node, {int? index});

  /// Removes nodes as part of this edit.
  void removeAll(Iterable<NodeId> ids);

  /// Reorders the scoped container's immediate children.
  void reorder(Iterable<NodeId> ids);

  /// Closes the edit and returns its change, or null when nothing changed.
  Commit? commit();

  /// Restores the document to its state before this edit.
  void cancel();
}
