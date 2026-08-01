import 'package:squiggle_flutter/models/document.dart';

/// A reversible edit to a [Document].
///
/// Commands capture the before and after state so the same instance can be
/// applied ([redo]) and reversed ([undo]) any number of times. The command
/// layer records commands; [Document] itself has no history concept.
abstract class Command {
  const Command();

  /// Applies (or re-applies) the final state to [document].
  void redo(Document document);

  /// Reverses the last [redo] of this command on [document].
  void undo(Document document);
}
