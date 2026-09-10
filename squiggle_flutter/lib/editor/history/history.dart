import 'package:squiggle_flutter/editor/history/edit.dart';
import 'package:squiggle_flutter/models/document.dart';
import 'package:squiggle_flutter/models/node.dart';

export 'edit.dart';

class History {
  Transaction? _active;
  final Document _document;

  final List<Commit> _undoStack = [];
  final List<Commit> _redoStack = [];

  History(this._document);

  Transaction? get active => _active;

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

  void undo() {
    if (_undoStack.isEmpty) {
      throw StateError('No commits to undo');
    }

    final commit = _undoStack.removeLast();
    commit.undo(_document);
  }

  void redo() {
    if (_redoStack.isEmpty) {
      throw StateError('No commits to redo');
    }

    final commit = _redoStack.removeLast();
    commit.redo(_document);
  }

  void commit() {
    if (_active == null) {
      throw StateError('No transaction is active');
    }

    final commit = _active!.commit();
    if (commit != null) {
      _undoStack.add(commit);
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
    action(_active!);
    commit();
  }
}
