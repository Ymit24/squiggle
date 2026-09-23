import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

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
      buttonBuilder: (context, open, toggle) => SquiggleButton(
        key: const ValueKey('library-sort'),
        onPressed: toggle,
        icon: Icons.swap_vert_rounded,
        label: _label,
        variant: SquiggleButtonVariant.secondary,
        compact: compact,
      ),
    );
  }
}
