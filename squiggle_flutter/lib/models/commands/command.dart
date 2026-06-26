import 'dart:ui';

import '../document.dart';
import '../feature.dart';
import '../feature_geometry.dart';
import '../feature_id.dart';

part 'add_feature_command.dart';
part 'add_features_command.dart';
part 'move_feature_command.dart';
part 'move_polyline_point_command.dart';
part 'remove_features_command.dart';
part 'resize_feature_command.dart';
part 'update_features_style_command.dart';
part 'update_text_contents_command.dart';

/// A reversible edit to a [Document].
///
/// Commands are applied via [Document.executeCommand] and stored on the undo
/// stack. [clone] produces a snapshot suitable for undo/redo.
sealed class Command {
  const Command();

  /// Applies this edit to [document].
  void apply(Document document);

  /// Reverses the last [apply] of this command on [document].
  void undo(Document document);

  /// Returns a copy of this command, including any state captured during
  /// [apply] that is needed to [undo].
  Command clone();
}
