import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/document_preview_loader.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class DocumentCard extends StatefulWidget {
  const DocumentCard({
    super.key,
    required this.document,
    required this.isCurrent,
    required this.canDelete,
    required this.onOpen,
    required this.onRename,
    required this.onDelete,
  });

  final DocumentInfo document;
  final bool isCurrent;
  final bool canDelete;
  final VoidCallback onOpen;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  State<DocumentCard> createState() => _DocumentCardState();
}

class _DocumentCardState extends State<DocumentCard> {
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
        onSecondaryTap: () => _showActions(context),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: colors.mantle,
            borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
            border: Border.all(
              color: widget.isCurrent
                  ? colors.accent.withValues(alpha: 0.75)
                  : _hovering
                  ? colors.surface1
                  : colors.surface1.withValues(alpha: 0.65),
              width: widget.isCurrent ? 1.5 : 1,
            ),
            boxShadow: _hovering
                ? [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.08),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                  child: Stack(
                    children: [
                      DocumentPreviewLoader(document: widget.document),
                      if (_hovering || widget.isCurrent)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _CardMenuButton(
                            canDelete: widget.canDelete,
                            onRename: widget.onRename,
                            onDelete: widget.onDelete,
                          ),
                        ),
                      if (widget.isCurrent)
                        Positioned(
                          left: 8,
                          top: 8,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.accent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: colors.accent.withValues(alpha: 0.35),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: Text(
                                'Recent',
                                style: theme.typography.hotkey.copyWith(
                                  color: colors.accent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.document.name,
                      style: theme.typography.inputText.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(widget.document),
                      style: theme.typography.hotkey.copyWith(fontSize: 11),
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

  void _showActions(BuildContext context) {
    showMenu<void>(
      context: context,
      position: const RelativeRect.fromLTRB(200, 200, 0, 0),
      color: context.squiggleTheme.colors.mantle,
      items: [
        PopupMenuItem(onTap: widget.onRename, child: const Text('Rename')),
        if (widget.canDelete)
          PopupMenuItem(onTap: widget.onDelete, child: const Text('Delete')),
      ],
    );
  }

  String _subtitle(DocumentInfo document) {
    final featureLabel = document.featureCount == 1
        ? '1 shape'
        : '${document.featureCount} shapes';
    return '$featureLabel · ${_formatUpdatedAt(document.updatedAt)}';
  }

  String _formatUpdatedAt(DateTime updatedAt) {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    if (difference.inMinutes < 1) {
      return 'Edited just now';
    }
    if (difference.inHours < 1) {
      return 'Edited ${difference.inMinutes}m ago';
    }
    if (difference.inDays < 1) {
      return 'Edited ${difference.inHours}h ago';
    }
    if (difference.inDays < 7) {
      return 'Edited ${difference.inDays}d ago';
    }
    return 'Edited ${updatedAt.month}/${updatedAt.day}/${updatedAt.year}';
  }
}

class _CardMenuButton extends StatefulWidget {
  const _CardMenuButton({
    required this.canDelete,
    required this.onRename,
    required this.onDelete,
  });

  final bool canDelete;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  State<_CardMenuButton> createState() => _CardMenuButtonState();
}

class _CardMenuButtonState extends State<_CardMenuButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: PopupMenuButton<void>(
        tooltip: 'Document actions',
        padding: EdgeInsets.zero,
        color: theme.colors.mantle,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radii.button),
          side: BorderSide(color: theme.colors.surface1),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            onTap: () => Future.microtask(widget.onRename),
            child: const Text('Rename'),
          ),
          if (widget.canDelete)
            PopupMenuItem(
              onTap: () => Future.microtask(widget.onDelete),
              child: const Text('Delete'),
            ),
        ],
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colors.mantle.withValues(alpha: _hovering ? 1 : 0.92),
            borderRadius: BorderRadius.circular(theme.radii.button),
            border: Border.all(color: theme.colors.surface1),
          ),
          child: const SizedBox(
            width: 28,
            height: 28,
            child: Icon(Icons.more_horiz, size: 16),
          ),
        ),
      ),
    );
  }
}
