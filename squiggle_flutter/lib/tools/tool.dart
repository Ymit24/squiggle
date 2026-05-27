import 'dart:ui';

import 'package:squiggle_flutter/repositories/document_repository.dart';
import 'package:squiggle_flutter/repositories/selection.dart';

/// Active editor tool: pointer handling and ephemeral overlay painting.
abstract class Tool {
  const Tool();

  /// Paints tool-specific overlays in world space (after the world transform).
  void paint(Canvas canvas);

  void onPointerDown(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
  );

  void onPointerMove(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
  );

  void onPointerUp(
    DocumentRepository documentRepository,
    Offset worldPosition,
    SelectionRepository selection,
    bool isShiftPressed,
  );

  void deactivate(SelectionRepository selection);
}
