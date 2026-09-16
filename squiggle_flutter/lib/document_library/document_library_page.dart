import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/document_library/widgets/document_card.dart';
import 'package:squiggle_flutter/document_library/widgets/document_name_dialog.dart';
import 'package:squiggle_flutter/document_library/widgets/document_preview_loader.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu.dart';
import 'package:squiggle_flutter/document_library/widgets/library_time.dart';
import 'package:squiggle_flutter/document_library/widgets/new_document_card.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

enum _SortMode { recent, oldest, name }

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
  String _query = '';
  _SortMode _sort = _SortMode.recent;

  @override
  void initState() {
    super.initState();
    // Rebuild so the search field can reflect focus changes in its border.
    _searchFocus.addListener(_onSearchFocusChanged);
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchFocus.removeListener(_onSearchFocusChanged);
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final library = context.read<DocumentLibraryRepository>();

    return Scaffold(
      backgroundColor: theme.colors.base,
      // CallbackShortcuts only sees keys when focus is inside its subtree,
      // so the autofocus Focus node must sit *below* it, not above.
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.keyN, meta: true):
              () => widget.onCreateAndOpen(),
          const SingleActivator(LogicalKeyboardKey.keyN, control: true):
              () => widget.onCreateAndOpen(),
          const SingleActivator(LogicalKeyboardKey.slash, meta: true): () =>
              _searchFocus.requestFocus(),
          const SingleActivator(LogicalKeyboardKey.slash, control: true):
              () => _searchFocus.requestFocus(),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              const _BackdropGlow(),
              SafeArea(
                child: Column(
                  children: [
                    _StickyHeader(
                      searchController: _searchController,
                      searchFocus: _searchFocus,
                      query: _query,
                      sort: _sort,
                      onQueryChanged: (value) =>
                          setState(() => _query = value),
                      onClearQuery: () {
                        _searchController.clear();
                        setState(() => _query = '');
                      },
                      onSortChanged: (mode) =>
                          setState(() => _sort = mode),
                      onCreateNamed: () =>
                          _createNamedDocument(context),
                    ),
                    Expanded(
                      child: StreamBuilder<void>(
                        stream: library.changesStream,
                        initialData: null,
                        builder: (context, _) {
                          final documents =
                              _sorted(_filtered(library.documents));
                          final currentId = library.currentDocument?.id;
                          final featured = _featuredDocument(library);

                          return CustomScrollView(
                            slivers: [
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 1160),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  40, 30, 40, 0),
                              child: _TitleBlock(
                                totalCount: library.documents.length,
                                visibleCount: documents.length,
                                isSearching: _query.trim().isNotEmpty,
                                query: _query.trim(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (featured != null && _query.trim().isEmpty)
                        SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 1160),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    40, 22, 40, 0),
                                child: _FeaturedCard(
                                  document: featured,
                                  isCurrent: featured.id == currentId,
                                  onOpen: () =>
                                      widget.onOpenDocument(featured.id),
                                  onRename: () => _renameDocument(
                                    context,
                                    library,
                                    featured,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      SliverToBoxAdapter(
                        child: Center(
                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(maxWidth: 1160),
                            child: Padding(
                              padding:
                                  const EdgeInsets.fromLTRB(40, 26, 40, 8),
                              child: _SectionHeader(
                                title: _query.trim().isEmpty
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
                              constraints:
                                  const BoxConstraints(maxWidth: 1160),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    40, 8, 40, 64),
                                child: _EmptyResults(
                                  isSearching: _query.trim().isNotEmpty,
                                  onClear: () {
                                    _searchController.clear();
                                    setState(() => _query = '');
                                  },
                                  onCreate: () =>
                                      widget.onCreateAndOpen(),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        SliverToBoxAdapter(
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 1160),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    40, 8, 40, 56),
                                child: LayoutBuilder(
                                  builder: (context, constraints) {
                                    final crossAxisCount =
                                        _gridColumnCount(
                                      constraints.maxWidth,
                                    );
                                    const spacing = 18.0;
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        mainAxisSpacing: spacing,
                                        crossAxisSpacing: spacing,
                                        childAspectRatio: 0.94,
                                      ),
                                      itemCount: _query.trim().isEmpty
                                          ? documents.length + 1
                                          : documents.length,
                                      itemBuilder: (context, index) {
                                        if (_query.trim().isEmpty &&
                                            index == 0) {
                                          return NewDocumentCard(
                                            onPressed: () =>
                                                widget.onCreateAndOpen(),
                                          );
                                        }
                                        final docIndex =
                                            _query.trim().isEmpty
                                                ? index - 1
                                                : index;
                                        final document =
                                            documents[docIndex];
                                        return DocumentCard(
                                          document: document,
                                          isCurrent:
                                              document.id == currentId,
                                          canDelete:
                                              library.documents.length > 1,
                                          onOpen: () => widget
                                              .onOpenDocument(document.id),
                                          onRename: () =>
                                              _renameDocument(
                                            context,
                                            library,
                                            document,
                                          ),
                                          onDelete: () =>
                                              _deleteDocument(
                                            context,
                                            library,
                                            document,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
          (a, b) =>
              a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
        break;
    }
    return documents;
  }

  DocumentInfo? _featuredDocument(DocumentLibraryRepository library) {
    if (library.documents.isEmpty) return null;
    final sorted = List.of(library.documents)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    // Only feature when there's something worth continuing.
    if (library.documents.length < 2) return null;
    return sorted.first;
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

class _BackdropGlow extends StatelessWidget {
  const _BackdropGlow();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0.0, -1.4),
          radius: 1.1,
          colors: [Color(0xFF26262F), Color(0xFF171717)],
          stops: [0.0, 0.62],
        ),
      ),
      child: SizedBox.expand(),
    );
  }
}

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({
    required this.searchController,
    required this.searchFocus,
    required this.query,
    required this.sort,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSortChanged,
    required this.onCreateNamed,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
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
        border: const Border(
          bottom: BorderSide(color: Color(0xFF23232C)),
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1160),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(40, 14, 40, 14),
            child: _TopBar(
              searchController: searchController,
              searchFocus: searchFocus,
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
    required this.query,
    required this.sort,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onSortChanged,
    required this.onCreateNamed,
  });

  final TextEditingController searchController;
  final FocusNode searchFocus;
  final String query;
  final _SortMode sort;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<_SortMode> onSortChanged;
  final VoidCallback onCreateNamed;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF3A3A48), Color(0xFF22222B)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF3E3E4E)),
          ),
          child: const Icon(
            Icons.gesture_rounded,
            size: 19,
            color: Color(0xFFE4E4E4),
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
        const Spacer(),
        SizedBox(
          width: 250,
          child: _SearchField(
            controller: searchController,
            focusNode: searchFocus,
            query: query,
            onChanged: onQueryChanged,
            onClear: onClearQuery,
          ),
        ),
        const SizedBox(width: 10),
        _SortButton(sort: sort, onChanged: onSortChanged),
        const SizedBox(width: 10),
        _NewButton(onTap: onCreateNamed),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.query,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String query;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C23),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: focusNode.hasFocus
              ? theme.colors.accent.withValues(alpha: 0.6)
              : const Color(0xFF2C2C38),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          Icon(
            Icons.search_rounded,
            size: 17,
            color: theme.colors.subtext0,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A35),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: const Color(0xFF363644)),
                ),
                child: Text(
                  '⌘/',
                  style: theme.typography.hotkey.copyWith(fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({required this.sort, required this.onChanged});

  final _SortMode sort;
  final ValueChanged<_SortMode> onChanged;

  String get _label => switch (sort) {
        _SortMode.recent => 'Recent',
        _SortMode.oldest => 'Oldest',
        _SortMode.name => 'Name',
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
              duration: const Duration(milliseconds: 140),
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: open
                    ? const Color(0xFF23232E)
                    : const Color(0xFF1C1C23),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: open
                      ? theme.colors.accent.withValues(alpha: 0.5)
                      : const Color(0xFF2C2C38),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.swap_vert_rounded,
                      size: 16, color: theme.colors.subtext0),
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NewButton extends StatefulWidget {
  const _NewButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_NewButton> createState() => _NewButtonState();
}

class _NewButtonState extends State<_NewButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: _hovering
                ? const Color(0xFFF0F0F5)
                : theme.colors.text,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: Colors.black87),
              SizedBox(width: 6),
              Text(
                'New canvas',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({
    required this.totalCount,
    required this.visibleCount,
    required this.isSearching,
    required this.query,
  });

  final int totalCount;
  final int visibleCount;
  final bool isSearching;
  final String query;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSearching ? 'Search' : 'Your documents',
          style: theme.typography.inputText.copyWith(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isSearching
              ? '$visibleCount of ${formatLibraryCount(totalCount)} match "$query"'
              : '${formatLibraryCount(totalCount)} ready to open · double-click a card to rename',
          style: theme.typography.inputText.copyWith(
            color: theme.colors.subtext0,
            fontSize: 13.5,
          ),
        ),
      ],
    );
  }
}

class _FeaturedCard extends StatefulWidget {
  const _FeaturedCard({
    required this.document,
    required this.isCurrent,
    required this.onOpen,
    required this.onRename,
  });

  final DocumentInfo document;
  final bool isCurrent;
  final VoidCallback onOpen;
  final VoidCallback onRename;

  @override
  State<_FeaturedCard> createState() => _FeaturedCardState();
}

class _FeaturedCardState extends State<_FeaturedCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1E28), Color(0xFF17171D)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovering
                  ? colors.accent.withValues(alpha: 0.5)
                  : const Color(0xFF2E2E3B),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: SizedBox(
            height: 240,
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: DocumentPreviewLoader(
                      document: widget.document),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(22, 10, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.document.name,
                          style: theme.typography.inputText.copyWith(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatLibraryEditedAt(
                              widget.document.updatedAt),
                          style: theme.typography.inputText.copyWith(
                            color: colors.subtext0,
                            fontSize: 13,
                          ),
                        ),
                        if (widget.isCurrent) ...[
                          const SizedBox(height: 10),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7EE2A8),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Currently open',
                                style: theme.typography.inputText
                                    .copyWith(
                                  color: colors.subtext0,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 22),
                        Row(
                          children: [
                            _FeaturedPrimaryButton(
                              label: widget.isCurrent
                                  ? 'Continue'
                                  : 'Open canvas',
                              onTap: widget.onOpen,
                            ),
                            const SizedBox(width: 10),
                            _FeaturedGhostButton(
                              icon: Icons
                                  .drive_file_rename_outline_rounded,
                              tooltip: 'Rename',
                              onTap: widget.onRename,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedPrimaryButton extends StatefulWidget {
  const _FeaturedPrimaryButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  State<_FeaturedPrimaryButton> createState() =>
      _FeaturedPrimaryButtonState();
}

class _FeaturedPrimaryButtonState extends State<_FeaturedPrimaryButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            color: _hovering
                ? const Color(0xFFF2F2F6)
                : const Color(0xFFE4E4E4),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 7),
              const Icon(Icons.arrow_forward_rounded,
                  size: 16, color: Colors.black87),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturedGhostButton extends StatefulWidget {
  const _FeaturedGhostButton(
      {required this.icon, required this.tooltip, required this.onTap});

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_FeaturedGhostButton> createState() => _FeaturedGhostButtonState();
}

class _FeaturedGhostButtonState extends State<_FeaturedGhostButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _hovering
                  ? const Color(0xFF2A2A35)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF363644)),
            ),
            child: Icon(widget.icon,
                size: 17, color: theme.colors.subtext0),
          ),
        ),
      ),
    );
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
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: const Color(0xFF23232D),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: const Color(0xFF30303E)),
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
        const Expanded(
          child: Divider(color: Color(0xFF26262F), thickness: 1),
        ),
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
        color: const Color(0xFF16161C).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF26262F)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF22222C),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF33333F)),
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
            TextButton(
              onPressed: onClear,
              child: const Text('Clear search'),
            )
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
      backgroundColor: const Color(0xFF1D1D25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF363644)),
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
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
          ),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFD95F5F),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 18, vertical: 10),
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
