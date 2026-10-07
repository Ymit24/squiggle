import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/editor/history/edit.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/node.dart';

export 'package:squiggle_flutter/editor/history/edit.dart';

/// Manages the active document edit and its undo and redo history.
///
/// Listeners are notified when the committed history changes or an active edit
/// is canceled. Mutations to the active transaction itself do not notify.
class History extends ChangeNotifier {
  /// Creates a history manager for [document].
  History({required this._document});

  Transaction? _active;
  final Document _document;

  final List<Commit> _undoStack = [];
  final List<Commit> _redoStack = [];

  /// The current transaction.
  ///
  /// Throws a [StateError] when [isActive] is false.
  Transaction get active => _active!;

  /// Whether a transaction is currently open.
  bool get isActive => _active != null;

  /// Whether a previously committed edit can be undone.
  bool get canUndo => _undoStack.isNotEmpty;

  /// Whether an undone edit can be redone.
  bool get canRedo => _redoStack.isNotEmpty;

  /// Starts an edit labeled [label], scoped to [container].
  ///
  /// When [container] is omitted, the edit is scoped to the document. Throws a
  /// [StateError] if another transaction is already active.
  void begin(String label, {NodeContainer? container}) {
    if (_active != null) {
      throw StateError('A transaction is already active');
    }

    _active = DocumentTransaction(
      document: _document,
      label: label,
      container: container,
    );
  }

  /// Discards all undo and redo history and notifies listeners.
  ///
  /// Throws a [StateError] if a transaction is active.
  void clear() {
    if (_active != null) {
      throw StateError('Cannot clear while a transaction is active');
    }
    _active = null;
    _undoStack.clear();
    _redoStack.clear();

    notifyListeners();
  }

  /// Undoes the most recently committed edit and notifies listeners.
  ///
  /// Throws a [StateError] if there is no edit to undo or a transaction is
  /// active.
  void undo() {
    if (_undoStack.isEmpty) {
      throw StateError('No commits to undo');
    }
    if (_active != null) {
      throw StateError('Cannot undo while a transaction is active');
    }

    final commit = _undoStack.last;
    commit.undo(_document);
    _undoStack.removeLast();
    _redoStack.add(commit);

    notifyListeners();
  }

  /// Reapplies the most recently undone edit and notifies listeners.
  ///
  /// Throws a [StateError] if there is no edit to redo or a transaction is
  /// active.
  void redo() {
    if (_redoStack.isEmpty) {
      throw StateError('No commits to redo');
    }
    if (_active != null) {
      throw StateError('Cannot redo while a transaction is active');
    }

    final commit = _redoStack.last;
    commit.redo(_document);
    _redoStack.removeLast();
    _undoStack.add(commit);

    notifyListeners();
  }

  /// Commits the active transaction.
  ///
  /// A non-empty commit is added to the undo history and clears the redo
  /// history. Listeners are notified only when a commit is added. Throws a
  /// [StateError] if no transaction is active.
  void commit() {
    if (_active == null) {
      throw StateError('No transaction is active');
    }

    final commit = _active!.commit();
    _active = null;

    if (commit != null) {
      _undoStack.add(commit);
      _redoStack.clear();

      notifyListeners();
    }
  }

  /// Cancels the active transaction, restores its changes, and notifies
  /// listeners.
  ///
  /// Throws a [StateError] if no transaction is active.
  void cancel() {
    if (_active == null) {
      throw StateError('No transaction is active');
    }

    _active!.cancel();
    _active = null;

    notifyListeners();
  }

  /// Runs [action] in a transaction labeled [label], then commits it.
  ///
  /// If [action] throws, the transaction is canceled and the error is
  /// rethrown. When [container] is omitted, the transaction is scoped to the
  /// document. Throws a [StateError] if a transaction is already active.
  void run(
    String label,
    void Function(Transaction transaction) action, {
    NodeContainer? container,
  }) {
    begin(label, container: container);
    try {
      action(_active!);
      commit();
    } catch (_) {
      cancel();
      rethrow;
    }
  }
}
