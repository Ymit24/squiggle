import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/document_library/widgets/document_card.dart';
import 'package:squiggle_flutter/document_library/widgets/document_name_dialog.dart';
import 'package:squiggle_flutter/document_library/widgets/new_document_card.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/repositories/document_library_repository.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class DocumentLibraryPage extends StatelessWidget {
  const DocumentLibraryPage({
    super.key,
    required this.onOpenDocument,
    required this.onCreateAndOpen,
  });

  final Future<void> Function(String id) onOpenDocument;
  final Future<void> Function({String? name}) onCreateAndOpen;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final library = context.read<DocumentLibraryRepository>();

    return Scaffold(
      backgroundColor: theme.colors.base,
      body: SafeArea(
        child: StreamBuilder<void>(
          stream: library.changesStream,
          initialData: null,
          builder: (context, _) {
            final documents = library.documents;
            final currentId = library.currentDocument?.id;

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 28, 32, 8),
                    child: _LibraryHeader(
                      documentCount: documents.length,
                      onCreateNamed: () => _createNamedDocument(context, library),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 40),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = _gridColumnCount(constraints.maxWidth);
                        const spacing = 20.0;
                        const cardAspectRatio = 0.82;

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            mainAxisSpacing: spacing,
                            crossAxisSpacing: spacing,
                            childAspectRatio: cardAspectRatio,
                          ),
                          itemCount: documents.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return NewDocumentCard(
                                onPressed: () => onCreateAndOpen(),
                              );
                            }

                            final document = documents[index - 1];
                            return DocumentCard(
                              document: document,
                              isCurrent: document.id == currentId,
                              canDelete: documents.length > 1,
                              onOpen: () => onOpenDocument(document.id),
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
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  int _gridColumnCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 560) return 2;
    return 1;
  }

  Future<void> _createNamedDocument(
    BuildContext context,
    DocumentLibraryRepository library,
  ) async {
    final name = await showDocumentNameDialog(
      context,
      title: 'New document',
      confirmLabel: 'Create',
      initialName: 'Untitled',
    );
    if (name == null || !context.mounted) {
      return;
    }
    await onCreateAndOpen(name: name);
  }

  Future<void> _renameDocument(
    BuildContext context,
    DocumentLibraryRepository library,
    DocumentInfo document,
  ) async {
    final name = await showDocumentNameDialog(
      context,
      title: 'Rename document',
      confirmLabel: 'Save',
      initialName: document.name,
    );
    if (name == null || !context.mounted) {
      return;
    }
    await library.renameDocument(document.id, name);
  }

  Future<void> _deleteDocument(
    BuildContext context,
    DocumentLibraryRepository library,
    DocumentInfo document,
  ) async {
    final theme = context.squiggleTheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colors.mantle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
          side: BorderSide(color: theme.colors.surface1),
        ),
        title: Text(
          'Delete document?',
          style: theme.typography.inputText.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        content: Text(
          '"${document.name}" will be permanently deleted.',
          style: theme.typography.inputText.copyWith(color: theme.colors.subtext0),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: theme.colors.subtext0)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: TextStyle(
                color: theme.colors.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }
    await library.deleteDocument(document.id);
  }
}

class _LibraryHeader extends StatefulWidget {
  const _LibraryHeader({
    required this.documentCount,
    required this.onCreateNamed,
  });

  final int documentCount;
  final VoidCallback onCreateNamed;

  @override
  State<_LibraryHeader> createState() => _LibraryHeaderState();
}

class _LibraryHeaderState extends State<_LibraryHeader> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Squiggle',
                style: theme.typography.inputText.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your documents',
                style: theme.typography.inputText.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.documentCount == 1
                    ? '1 canvas ready to open'
                    : '${widget.documentCount} canvases ready to open',
                style: theme.typography.inputText.copyWith(
                  color: colors.subtext0,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        MouseRegion(
          onEnter: (_) => setState(() => _hovering = true),
          onExit: (_) => setState(() => _hovering = false),
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onCreateNamed,
            child: DecoratedBox(
              decoration: theme.decorations.panelButton(
                isPrimary: true,
                isHovering: _hovering,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 18, color: colors.base),
                    const SizedBox(width: 8),
                    Text(
                      'New document',
                      style: theme.typography.panelButtonLabel(isPrimary: true),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
