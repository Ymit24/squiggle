import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/document_library/widgets/document_card.dart';
import 'package:squiggle_flutter/document_library/widgets/document_name_dialog.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu.dart';
import 'package:squiggle_flutter/document_library/widgets/new_document_card.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

enum _SortMode { recent, oldest, name }

const _compactLibraryBreakpoint = 760.0;
const _maxLibraryWidth = 1160.0;
const _headerControlHeight = 38.0;

bool _isCompactLibrary(BuildContext context) =>
    MediaQuery.sizeOf(context).width < _compactLibraryBreakpoint;

double _libraryHPadding(BuildContext context) =>
    _isCompactLibrary(context) ? 16.0 : 40.0;

class DocumentLibraryPage extends StatefulWidget {
  const DocumentLibraryPage({
    super.key,
    required this.onOpenDocument,
    required this.onCreateAndOpen,
  });

  final Future<void> Function(String id) onOpenDocument;
  final Future<void> Function({String? name}) onCreateAndOpen;

  @override
  State<DocumentLibraryPage> createState() => _DocumentLibraryPageState();
}

class _DocumentLibraryPageState extends State<DocumentLibraryPage> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _shortcutFocus = FocusNode();
  String _query = '';
  _SortMode _sort = _SortMode.recent;

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _shortcutFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final library = context.read<DocumentLibraryRepository>();

    return Scaffold(
      backgroundColor: theme.colors.mantle,
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true): () =>
              widget.onCreateAndOpen(),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true): () =>
              widget.onCreateAndOpen(),
          const SingleActivator(LogicalKeyboardKey.slash, meta: true): () =>
              _searchFocus.requestFocus(),
          const SingleActivator(LogicalKeyboardKey.slash, control: true): () =>
              _searchFocus.requestFocus(),
        },
        child: Focus(
          focusNode: _shortcutFocus,
          autofocus: true,
          child: SafeArea(
            child: Column(
              children: [
                _StickyHeader(
                  searchController: _searchController,
                  searchFocus: _searchFocus,
                  onSearchTapOutside: _shortcutFocus.requestFocus,
                  query: _query,
                  sort: _sort,
                  onQueryChanged: (value) => setState(() => _query = value),
                  onClearQuery: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                  onSortChanged: (mode) => setState(() => _sort = mode),
                  onCreateNamed: () => _createNamedDocument(context),
                ),
                Expanded(
                  child: StreamBuilder<void>(
                    stream: library.changesStream,
                    initialData: null,
                    builder: (context, _) {
                      final documents = _sorted(_filtered(library.documents));
                      final currentId = library.currentDocument?.id;
                      final hPad = _libraryHPadding(context);
                      final query = _query.trim();
                      final isSearching = query.isNotEmpty;

                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: _maxLibraryWidth,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    hPad,
                                    28,
                                    hPad,
                                    8,
                                  ),
                                  child: _SectionHeader(
                                    title: !isSearching
                                        ? 'All canvases'
                                        : 'Results',
                                    count: documents.length,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (documents.isEmpty)
                            SliverToBoxAdapter(
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: _maxLibraryWidth,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      hPad,
                                      8,
                                      hPad,
                                      64,
                                    ),
                                    child: _EmptyResults(
                                      isSearching: isSearching,
                                      onClear: () {
                                        _searchController.clear();
                                        setState(() => _query = '');
                                      },
                                      onCreate: () => widget.onCreateAndOpen(),
                                    ),
                                  ),
                                ),
                              ),
                            )
                          else
                            SliverLayoutBuilder(
                              builder: (context, constraints) {
                                final sectionWidth = constraints.crossAxisExtent
                                    .clamp(0.0, _maxLibraryWidth);
                                final sidePadding =
                                    (constraints.crossAxisExtent -
                                            sectionWidth) /
                                        2 +
                                    hPad;
                                final gridWidth = sectionWidth - 2 * hPad;
                                final crossAxisCount = _gridColumnCount(
                                  gridWidth,
                                );

                                return SliverPadding(
                                  padding: EdgeInsets.fromLTRB(
                                    sidePadding,
                                    8,
                                    sidePadding,
                                    56,
                                  ),
                                  sliver: SliverGrid(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: crossAxisCount,
                                          mainAxisSpacing: 18,
                                          crossAxisSpacing: 18,
                                          childAspectRatio: crossAxisCount == 1
                                              ? 1.6
                                              : 0.94,
                                        ),
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        if (!isSearching && index == 0) {
                                          return NewDocumentCard(
                                            onPressed: () =>
                                                widget.onCreateAndOpen(),
                                          );
                                        }
                                        final document =
                                            documents[isSearching
                                                ? index
                                                : index - 1];
                                        return DocumentCard(
                                          document: document,
                                          isCurrent: document.id == currentId,
                                          canDelete:
                                              library.documents.length > 1,
                                          onOpen: () => widget.onOpenDocument(
                                            document.id,
                                          ),
                                          onRename: () => _renameDocument(
                                            context,
                                            library,
                                            document,
                                          ),
                                          onDelete: () => _deleteDocument(
                                            context,
                                            library,
                                            document,
                                          ),
                                        );
                                      },
                                      childCount:
                                          documents.length +
                                          (isSearching ? 0 : 1),
                                    ),
                                  ),
                                );
                              },
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DocumentInfo> _filtered(List<DocumentInfo> documents) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return List.of(documents);
    return documents
        .where((doc) => doc.name.toLowerCase().contains(query))
        .toList();
  }

  List<DocumentInfo> _sorted(List<DocumentInfo> documents) {
    switch (_sort) {
      case _SortMode.recent:
        documents.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case _SortMode.oldest:
        documents.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case _SortMode.name:
        documents.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }
    return documents;
  }

  int _gridColumnCount(double width) {
    if (width >= 1020) return 3;
    if (width >= 680) return 2;
    return 1;
  }

  Future<void> _createNamedDocument(BuildContext context) async {
    final name = await showDocumentNameDialog(
      context,
      title: 'New canvas',
      confirmLabel: 'Create',
      initialName: 'Untitled',
    );
    if (name == null || !context.mounted) return;
    await widget.onCreateAndOpen(name: name);
  }

  Future<void> _renameDocument(
    BuildContext context,
    DocumentLibraryRepository library,
    DocumentInfo document,
  ) async {
    final name = await showDocumentNameDialog(
      context,
      title: 'Rename canvas',
      confirmLabel: 'Save',
      initialName: document.name,
    );
    if (name == null || !context.mounted) return;
    await library.renameDocument(document.id, name);
  }

  Future<void> _deleteDocument(
    BuildContext context,
    DocumentLibraryRepository library,
    DocumentInfo document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteDialog(document: document),
    );
    if (confirmed != true || !context.mounted) return;
    await library.deleteDocument(document.id);
  }
}

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
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
  final _SortMode sort;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<_SortMode> onSortChanged;
  final VoidCallback onCreateNamed;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.base,
        border: Border(bottom: BorderSide(color: theme.colors.surface0)),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              _libraryHPadding(context),
              14,
              _libraryHPadding(context),
              14,
            ),
            child: _TopBar(
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
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
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
  final _SortMode sort;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<_SortMode> onSortChanged;
  final VoidCallback onCreateNamed;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final compact = _isCompactLibrary(context);
    final searchField = _SearchField(
      controller: searchController,
      focusNode: searchFocus,
      onTapOutside: onSearchTapOutside,
      query: query,
      onChanged: onQueryChanged,
      onClear: onClearQuery,
    );
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colors.surface0,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: theme.colors.surface1),
          ),
          child: Icon(
            Icons.gesture_rounded,
            size: 19,
            color: theme.colors.text,
          ),
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
        _SortButton(sort: sort, onChanged: onSortChanged, compact: compact),
        const SizedBox(width: 10),
        _NewButton(onTap: onCreateNamed, compact: compact),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onTapOutside,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onTapOutside;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return ListenableBuilder(
      listenable: focusNode,
      builder: (context, child) => Container(
        key: const ValueKey('library-search'),
        height: _headerControlHeight,
        decoration: BoxDecoration(
          color: theme.colors.surface0,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: focusNode.hasFocus
                ? theme.colors.accent.withValues(alpha: 0.6)
                : theme.colors.surface1,
          ),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(Icons.search_rounded, size: 17, color: theme.colors.subtext0),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                onTapOutside: (_) => onTapOutside(),
                onChanged: onChanged,
                style: theme.typography.inputText.copyWith(fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Search canvases…',
                  hintStyle: TextStyle(
                    color: theme.colors.subtext0.withValues(alpha: 0.7),
                    fontSize: 13.5,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (query.isNotEmpty)
              GestureDetector(
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    Icons.close_rounded,
                    size: 15,
                    color: theme.colors.subtext0,
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colors.surface1,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: theme.colors.surface1),
                  ),
                  child: Text(
                    '⌘/',
                    style: theme.typography.hotkey.copyWith(fontSize: 10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.sort,
    required this.onChanged,
    this.compact = false,
  });

  final _SortMode sort;
  final ValueChanged<_SortMode> onChanged;
  final bool compact;

  String get _label => switch (sort) {
    _SortMode.recent => 'Recent',
    _SortMode.oldest => 'Oldest',
    _SortMode.name => 'Name',
  };

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return LibraryMenuAnchor(
      menuWidth: 232,
      menuItems: () => [
        LibraryMenuItem(
          label: 'Last edited',
          icon: Icons.schedule_rounded,
          checked: sort == _SortMode.recent,
          onTap: () => onChanged(_SortMode.recent),
        ),
        LibraryMenuItem(
          label: 'Oldest first',
          icon: Icons.history_rounded,
          checked: sort == _SortMode.oldest,
          onTap: () => onChanged(_SortMode.oldest),
        ),
        LibraryMenuItem(
          label: 'Name A–Z',
          icon: Icons.sort_by_alpha_rounded,
          checked: sort == _SortMode.name,
          onTap: () => onChanged(_SortMode.name),
        ),
      ],
      buttonBuilder: (context, open, toggle) => MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: toggle,
          child: Tooltip(
            message: 'Sort canvases',
            child: AnimatedContainer(
              key: const ValueKey('library-sort'),
              duration: const Duration(milliseconds: 140),
              height: _headerControlHeight,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: open ? theme.colors.surface1 : theme.colors.surface0,
                borderRadius: BorderRadius.circular(10),
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
                      duration: const Duration(milliseconds: 160),
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
      ),
    );
  }
}

class _NewButton extends StatelessWidget {
  const _NewButton({required this.onTap, this.compact = false});

  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final button = SizedBox(
      key: const ValueKey('library-new'),
      height: _headerControlHeight,
      child: TextButton(
        onPressed: onTap,
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? theme.colors.text.withValues(alpha: 0.9)
                : theme.colors.text,
          ),
          foregroundColor: WidgetStatePropertyAll(theme.colors.base),
          minimumSize: const WidgetStatePropertyAll(
            Size(0, _headerControlHeight),
          ),
          maximumSize: const WidgetStatePropertyAll(
            Size(double.infinity, _headerControlHeight),
          ),
          fixedSize: compact
              ? const WidgetStatePropertyAll(Size.square(_headerControlHeight))
              : null,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: WidgetStatePropertyAll(
            compact
                ? EdgeInsets.zero
                : const EdgeInsets.symmetric(horizontal: 11),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
          ),
        ),
        child: compact
            ? const Icon(Icons.add_rounded, size: 18)
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, size: 17),
                  SizedBox(width: 5),
                  Text(
                    'New canvas',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
    if (compact) {
      return Tooltip(message: 'New canvas', child: button);
    }
    return button;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Row(
      children: [
        Text(
          title,
          style: theme.typography.inputText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: theme.colors.subtext0,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: theme.colors.surface0,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: theme.colors.surface1),
          ),
          child: Text(
            '$count',
            style: theme.typography.hotkey.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: theme.colors.surface0, thickness: 1)),
      ],
    );
  }
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults({
    required this.isSearching,
    required this.onClear,
    required this.onCreate,
  });

  final bool isSearching;
  final VoidCallback onClear;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colors.base,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colors.surface0),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colors.surface0,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colors.surface1),
            ),
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.dashboard_customize_outlined,
              size: 24,
              color: theme.colors.subtext0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No canvases found' : 'No canvases yet',
            style: theme.typography.inputText.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Try a different search term.'
                : 'Create your first canvas to get started.',
            style: theme.typography.inputText.copyWith(
              color: theme.colors.subtext0,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 18),
          if (isSearching)
            TextButton(onPressed: onClear, child: const Text('Clear search'))
          else
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded, size: 17),
              label: const Text('New canvas'),
            ),
        ],
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.document});

  final DocumentInfo document;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return AlertDialog(
      backgroundColor: theme.colors.base,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colors.surface1),
      ),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFF28B8B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: Color(0xFFF28B8B),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Delete canvas?',
            style: theme.typography.inputText.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Text(
          '"${document.name}" will be permanently deleted. This cannot be undone.',
          style: theme.typography.inputText.copyWith(
            color: theme.colors.subtext0,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: theme.colors.subtext0,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD95F5F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(9),
            ),
          ),
          child: const Text(
            'Delete',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
