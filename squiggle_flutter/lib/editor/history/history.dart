import 'package:squiggle_flutter/editor/history/edit.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/node.dart';

export 'edit.dart';

class History {
  Transaction? _active;
  final Document _document;

  final List<Commit> _undoStack = [];
  final List<Commit> _redoStack = [];

  History({required this._document});

  Transaction get active => _active!;
  bool get isActive => _active != null;

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

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void clear() {
    if (_active != null) {
      throw StateError('Cannot clear while a transaction is active');
    }
    _active = null;
    _undoStack.clear();
    _redoStack.clear();
  }

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
  }

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
  }

  void commit() {
    if (_active == null) {
      throw StateError('No transaction is active');
    }

    final commit = _active!.commit();
    if (commit != null) {
      _undoStack.add(commit);
      _redoStack.clear();
    }

    _active = null;
  }

  void cancel() {
    if (_active == null) {
      throw StateError('No transaction is active');
    }

    _active!.cancel();
    _active = null;
  }

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
