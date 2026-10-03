import 'package:squiggle_flutter/editor/editor_context.dart';

/// A tool whose unfinished drawing can follow the active brush.
abstract interface class BrushPreviewTool {
  void refreshBrushPreview(EditorContext context);
}
