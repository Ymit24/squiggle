import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/models/commands/command.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/models/text_feature_placement.dart';
import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/viewport_repository.dart';
import 'package:squiggle_flutter/services/feature_clipboard.dart';

/// Creates a text feature from clipboard plain text at the viewport center.
Future<bool> pasteTextFromClipboard({
  required DocumentRepository documentRepository,
  required ViewportRepository viewportRepository,
}) async {
  final text = await readClipboardPlainText();
  if (text == null ||
      isSquiggleFeaturesClipboardText(text) ||
      text.trim().isEmpty) {
    return false;
  }

  final center = viewportRepository.worldCenterAtViewportCenter();
  if (center == null) {
    return false;
  }

  final feature = createTextFeatureAtCenter(contents: text, center: center);
  documentRepository.executeCommand(AddFeatureCommand(feature));
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
