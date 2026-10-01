import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/brush_menu_entry.dart';
import 'package:squiggle_flutter/models/brush_profile.dart';
import 'package:squiggle_flutter/models/document_session.dart';
import 'package:squiggle_flutter/repositories/image_repository.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// The handle is separate from the button so dragging never selects a brush.
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
    final theme = context.squiggleTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? theme.colors.surface0 : null,
        borderRadius: BorderRadius.circular(theme.radii.button),
      ),
      child: Row(
        children: [
          ReorderableDragStartListener(
            key: ValueKey('brush-drag-${brush.id}'),
            index: index,
            // Tooltip portals cannot safely move between this lazy list
            // and its drag overlay while the menu is laying out.
            child: Semantics(
              label: 'Drag to reorder ${brush.name}',
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: SizedBox(
                  width: theme.spacing.buttonIconSize,
                  child: Icon(
                    Icons.drag_indicator,
                    size: theme.spacing.buttonIconSize,
                    color: theme.colors.subtext0,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: BrushMenuEntry(
              brush: brush,
              selected: selected,
              shortcutNumber: index + 2 <= DocumentSession.maxBrushes
                  ? index + 2
                  : null,
              imageRepository: imageRepository,
              onPressed: onPressed,
            ),
          ),
        ],
      ),
    );
  }
}
