import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/brush_menu_entry.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/document_session.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';

/// A click selects; dragging anywhere on the entry reorders.
class BrushReorderRow extends StatelessWidget {
  const BrushReorderRow({
    super.key,
    required this.index,
    required this.brush,
    required this.selected,
    required this.imageRepository,
    required this.onPressed,
  });

  final int index;
  final BrushProfile brush;
  final bool selected;
  final ImageRepository imageRepository;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final entry = BrushMenuEntry(
      brush: brush,
      selected: selected,
      shortcutNumber: index + 2 <= DocumentSession.maxBrushes
          ? index + 2
          : null,
      imageRepository: imageRepository,
      mouseCursor: SystemMouseCursors.grab,
      onPressed: onPressed,
    );
    // Keep movable rows free of tooltip overlay portals.
    return ReorderableDragStartListener(
      key: ValueKey('brush-drag-${brush.id}'),
      index: index,
      child: entry,
    );
  }
}
