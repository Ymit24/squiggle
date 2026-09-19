import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_layout.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_pressable.dart';

enum DocumentSortMode { recent, oldest, name }

class LibrarySortButton extends StatelessWidget {
  const LibrarySortButton({
    super.key,
    required this.sort,
    required this.onChanged,
    this.compact = false,
  });

  final DocumentSortMode sort;
  final ValueChanged<DocumentSortMode> onChanged;
  final bool compact;

  String get _label => switch (sort) {
    DocumentSortMode.recent => 'Recent',
    DocumentSortMode.oldest => 'Oldest',
    DocumentSortMode.name => 'Name',
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return LibraryMenuAnchor(
      menuWidth: 216,
      menuItems: () => [
        LibraryMenuItem(
          label: 'Last edited',
          icon: Icons.schedule_rounded,
          checked: sort == DocumentSortMode.recent,
          onTap: () => onChanged(DocumentSortMode.recent),
        ),
        LibraryMenuItem(
          label: 'Oldest first',
          icon: Icons.history_rounded,
          checked: sort == DocumentSortMode.oldest,
          onTap: () => onChanged(DocumentSortMode.oldest),
        ),
        LibraryMenuItem(
          label: 'Name A–Z',
          icon: Icons.sort_by_alpha_rounded,
          checked: sort == DocumentSortMode.name,
          onTap: () => onChanged(DocumentSortMode.name),
        ),
      ],
      buttonBuilder: (context, open, toggle) => SquigglePressable(
        onPressed: toggle,
        semanticLabel: 'Sort canvases',
        builder: (context, state) => Tooltip(
          message: 'Sort canvases',
          child: AnimatedContainer(
            key: const ValueKey('library-sort'),
            duration: theme.motion.fast,
            height: libraryHeaderControlHeight,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: open || state.highlighted
                  ? theme.colors.surface1
                  : theme.colors.surface0,
              borderRadius: BorderRadius.circular(theme.radii.control),
              border: Border.all(
                color: open
                    ? theme.colors.accent.withValues(alpha: 0.5)
                    : theme.colors.surface1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swap_vert_rounded,
                  size: 16,
                  color: theme.colors.subtext0,
                ),
                if (!compact) ...[
                  const SizedBox(width: 7),
                  Text(
                    _label,
                    style: theme.typography.inputText.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: open ? 0.5 : 0,
                    duration: theme.motion.standard,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 17,
                      color: theme.colors.subtext0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
