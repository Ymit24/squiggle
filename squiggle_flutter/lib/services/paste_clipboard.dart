import 'package:squiggle_flutter/editor/editor_context.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/services/node_clipboard.dart';
import 'package:squiggle_flutter/services/paste_image.dart';
import 'package:squiggle_flutter/services/paste_text.dart';

Future<void> pasteFromClipboard({
  required EditorContext context,
  required ImageRepository imageRepository,
}) async {
  final pastedNodes = await pasteNodesFromClipboard(
    context: context,
    imageRepository: imageRepository,
  );
  if (pastedNodes) {
    return;
  }

  final pastedText = await pasteTextFromClipboard(context: context);
  if (pastedText) {
    return;
  }

  await pasteImageFromClipboard(
    imageRepository: imageRepository,
    context: context,
  );
}
