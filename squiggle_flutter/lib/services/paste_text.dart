import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
import 'package:squiggle_flutter/services/feature_clipboard.dart';

/// Creates a text feature from clipboard plain text at the viewport center.
Future<bool> pasteTextFromClipboard({
  required EditorContext context,
}) async {
  final text = await readClipboardPlainText();
  if (text == null ||
      isSquiggleFeaturesClipboardText(text) ||
      text.trim().isEmpty) {
    return false;
  }

  final center = context.worldCenterAtViewportCenter();
  if (center == null) {
    return false;
  }

  final feature = createTextFeatureAtCenter(contents: text, center: center);
  context.execute(AddFeatureCommand(feature));
  return true;
}

/// Testable helper for placing a text feature on the canvas.
Feature createTextFeatureAtCenter({
  required String contents,
  required Offset center,
}) {
  return repositionFeaturesToCenter(
    [newTextFeatureAt(Offset.zero, contents)],
    center,
  ).first;
}
