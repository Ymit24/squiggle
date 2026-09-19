import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/current_document_badge.dart';
import 'package:squiggle_flutter/document_library/widgets/document_card_menu_button.dart';
import 'package:squiggle_flutter/document_library/widgets/document_open_pill.dart';
import 'package:squiggle_flutter/document_library/widgets/document_preview_loader.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu.dart';
import 'package:squiggle_flutter/document_library/widgets/library_card_surface.dart';
import 'package:squiggle_flutter/document_library/widgets/library_time.dart';
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
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;

    return LibraryCardSurface(
      onPressed: widget.onOpen,
      onDoubleTap: widget.onRename,
      onSecondaryTapDown: (details) =>
          _showContextMenu(context, details.globalPosition),
      isCurrent: widget.isCurrent,
      forceHighlighted: _menuOpen,
      semanticLabel: widget.document.name,
      builder: (context, highlighted) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Stack(
                    fit: StackFit.expand,
                    children: [
                      DocumentPreviewLoader(document: widget.document),
                      AnimatedOpacity(
                        duration: theme.motion.fast,
                        opacity: highlighted ? 1 : 0,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              theme.radii.control,
                            ),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.42),
                              ],
                              stops: const [0.45, 1.0],
                            ),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DocumentOpenPill(
                                isCurrent: widget.isCurrent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedOpacity(
                      duration: theme.motion.fast,
                      opacity: (highlighted || widget.isCurrent) ? 1 : 0,
                      child: IgnorePointer(
                        ignoring: !(highlighted || widget.isCurrent),
                        child: DocumentCardMenuButton(
                          canDelete: widget.canDelete,
                          onRename: widget.onRename,
                          onDelete: widget.onDelete,
                          onOpenChanged: (open) =>
                              setState(() => _menuOpen = open),
                        ),
                      ),
                    ),
                  ),
                  if (widget.isCurrent)
                    const Positioned(
                      left: 8,
                      top: 8,
                      child: IgnorePointer(child: CurrentDocumentBadge()),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 10, 13),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.document.name,
                        style: theme.typography.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        formatLibraryEditedAt(widget.document.updatedAt),
                        style: theme.typography.caption.copyWith(
                          color: colors.subtext0.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: highlighted
                      ? colors.text.withValues(alpha: 0.8)
                      : colors.subtext0.withValues(alpha: 0.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    showLibraryContextMenu(
      context: context,
      position: position,
      items: [
        LibraryMenuItem(
          label: 'Rename',
          icon: Icons.drive_file_rename_outline,
          onTap: widget.onRename,
        ),
        if (widget.canDelete)
          LibraryMenuItem(
            label: 'Delete',
            icon: Icons.delete_outline_rounded,
            danger: true,
            onTap: widget.onDelete,
          ),
      ],
    );
  }
}
