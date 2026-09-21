import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/document_library/widgets/delete_document_dialog.dart';
import 'package:squiggle_flutter/document_library/widgets/document_card.dart';
import 'package:squiggle_flutter/document_library/widgets/document_name_dialog.dart';
import 'package:squiggle_flutter/document_library/widgets/empty_library_results.dart';
import 'package:squiggle_flutter/document_library/widgets/library_header.dart';
import 'package:squiggle_flutter/document_library/widgets/library_layout.dart';
import 'package:squiggle_flutter/document_library/widgets/library_section_header.dart';
import 'package:squiggle_flutter/document_library/widgets/library_sort_button.dart';
import 'package:squiggle_flutter/document_library/widgets/new_document_card.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

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
  DocumentSortMode _sort = DocumentSortMode.recent;

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
                LibraryHeader(
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
                      final hPad = kLibraryHorizontalPadding;
                      final query = _query.trim();
                      final isSearching = query.isNotEmpty;

                      return CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: maxLibraryWidth,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    hPad,
                                    28,
                                    hPad,
                                    8,
                                  ),
                                  child: LibrarySectionHeader(
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
                                    maxWidth: maxLibraryWidth,
                                  ),
                                  child: Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      hPad,
                                      8,
                                      hPad,
                                      64,
                                    ),
                                    child: EmptyLibraryResults(
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
                                    .clamp(0.0, maxLibraryWidth);
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
      case DocumentSortMode.recent:
        documents.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        break;
      case DocumentSortMode.oldest:
        documents.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
        break;
      case DocumentSortMode.name:
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
      builder: (context) => DeleteDocumentDialog(document: document),
    );
    if (confirmed != true || !context.mounted) return;
    await library.deleteDocument(document.id);
  }
}
