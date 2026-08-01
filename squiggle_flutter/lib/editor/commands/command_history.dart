import 'package:flutter/foundation.dart';
import 'package:squiggle_flutter/models/document.dart';

import 'command.dart';

/// Owns the undo/redo stacks for a [Document].
///
/// Gesture-driven edits mutate the document directly and are finalized with
/// [record] once the gesture completes; instant edits go through [execute],
/// which applies the command and then records it.
class CommandHistory extends ChangeNotifier {
  CommandHistory({required this.document});

  final Document document;

  final List<Command> _undoStack = [];
  final List<Command> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;

  bool get canRedo => _redoStack.isNotEmpty;

  int get undoCount => _undoStack.length;

  int get redoCount => _redoStack.length;

  /// Applies [command] to the document and records it for undo.
  void execute(Command command) {
    command.redo(document);
    _record(command);
  }

  /// Records an already-applied [command] (e.g. a gesture that mutated the
  /// document directly) without applying it again.
  void record(Command command) {
    _record(command);
  }

  void _record(Command command) {
    _undoStack.add(command);
    _redoStack.clear();
    notifyListeners();
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    final command = _undoStack.removeLast();
    command.undo(document);
    _redoStack.add(command);
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    final command = _redoStack.removeLast();
    command.redo(document);
    _undoStack.add(command);
    notifyListeners();
  }

  void clear() {
    if (_undoStack.isEmpty && _redoStack.isEmpty) return;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
