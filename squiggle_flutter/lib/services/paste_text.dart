import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
import 'package:squiggle_flutter/services/node_clipboard.dart';

/// Creates a text feature from clipboard plain text at the viewport center.
Future<bool> pasteTextFromClipboard({required EditorContext context}) async {
  final text = await readClipboardPlainText();
  if (text == null ||
      isSquiggleNodesClipboardText(text) ||
      text.trim().isEmpty) {
    return false;
  }

  final center = context.worldCenterAtViewportCenter();
  if (center == null) {
    return false;
  }

  final feature = createTextFeatureAtCenter(
    contents: text,
    center: center,
    configureKind: context.applyInspectorValues,
  );
  context.cancelInteraction();
  context.history.run('Create feature', (transaction) {
    transaction.add(feature);
  });
  return true;
}

/// Testable helper for placing a text feature on the canvas.
Feature createTextFeatureAtCenter({
  required String contents,
  required Offset center,
  void Function(FeatureKindText)? configureKind,
}) {
  final feature = newTextFeatureAt(
    Offset.zero,
    contents,
    configureKind: configureKind,
  );
  return repositionNodesToCenter([feature], center).first;
}
