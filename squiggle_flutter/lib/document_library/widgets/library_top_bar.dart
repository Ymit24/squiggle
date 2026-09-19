import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_layout.dart';
import 'package:squiggle_flutter/document_library/widgets/library_search_field.dart';
import 'package:squiggle_flutter/document_library/widgets/library_sort_button.dart';
import 'package:squiggle_flutter/document_library/widgets/new_document_button.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_icon_tile.dart';

class LibraryTopBar extends StatelessWidget {
  const LibraryTopBar({
    super.key,
    required this.searchController,
    required this.searchFocus,
    required this.onSearchTapOutside,
    required this.query,
    required this.sort,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSortChanged,
    required this.onCreateNamed,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final VoidCallback onSearchTapOutside;
  final String query;
  final DocumentSortMode sort;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<DocumentSortMode> onSortChanged;
  final VoidCallback onCreateNamed;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final compact = isCompactLibrary(context);
    final searchField = LibrarySearchField(
      controller: searchController,
      focusNode: searchFocus,
      onTapOutside: onSearchTapOutside,
      query: query,
      onChanged: onQueryChanged,
      onClear: onClearQuery,
    );
    return Row(
      children: [
        const SquiggleIconTile(
          icon: Icons.gesture_rounded,
          size: 36,
          iconSize: 19,
          tone: SquiggleIconTileTone.accent,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Squiggle',
              style: theme.typography.inputText.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                letterSpacing: 0.1,
              ),
            ),
            Text(
              'Canvas library',
              style: theme.typography.hotkey.copyWith(
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
        if (compact) ...[
          const SizedBox(width: 12),
          Expanded(child: searchField),
        ] else ...[
          const Spacer(),
          SizedBox(width: 250, child: searchField),
        ],
        const SizedBox(width: 10),
        LibrarySortButton(
          sort: sort,
          onChanged: onSortChanged,
          compact: compact,
        ),
        const SizedBox(width: 10),
        NewDocumentButton(onTap: onCreateNamed, compact: compact),
      ],
    );
  }
}
