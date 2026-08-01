import 'package:flutter/widgets.dart';
import 'package:squiggle_flutter/editor/commands/commands.dart';
import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/models/feature.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/feature_clipboard.dart';

/// Creates an image feature from a pasted clipboard image at the viewport center.
Future<void> pasteImageFromClipboard({
  required ImageRepository imageRepository,
  required EditorContext context,
}) async {
  final imported = await imageRepository.importFromClipboard();
  if (imported == null) {
    return;
  }

  final center = context.worldCenterAtViewportCenter();
  if (center == null) {
    return;
  }

  final feature = repositionFeaturesToCenter(
    [createImageFeatureAtCenter(imported: imported, center: center)],
    center,
  ).first;

  context.execute(AddFeatureCommand(feature));
}

/// Testable helper for placing an imported image feature on the canvas.
Feature createImageFeatureAtCenter({
  required ImportedImage imported,
  required Offset center,
}) {
  final size = clampImageWorldSize(imported.intrinsicSize);
  final origin = center - Offset(size.width / 2, size.height / 2);
  return Feature(
    origin: origin,
    size: size,
    kind: FeatureKindImage(imported.imageId),
  );
}
