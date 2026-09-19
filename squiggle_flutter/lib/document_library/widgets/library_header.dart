import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_content_bounds.dart';
import 'package:squiggle_flutter/document_library/widgets/library_sort_button.dart';
import 'package:squiggle_flutter/document_library/widgets/library_top_bar.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class LibraryHeader extends StatelessWidget {
  const LibraryHeader({
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.base,
        border: Border(bottom: BorderSide(color: theme.colors.surface0)),
      ),
      child: LibraryContentBounds(
        top: 14,
        bottom: 14,
        child: LibraryTopBar(
          searchController: searchController,
          searchFocus: searchFocus,
          onSearchTapOutside: onSearchTapOutside,
          query: query,
          sort: sort,
          onQueryChanged: onQueryChanged,
          onClearQuery: onClearQuery,
          onSortChanged: onSortChanged,
          onCreateNamed: onCreateNamed,
        ),
      ),
    );
  }
}
