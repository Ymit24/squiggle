import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/document_preview_loader.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu.dart';
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
  bool _hovering = false;
  bool _focused = false;
  bool _menuOpen = false;

  bool get _elevated => _hovering || _focused || _menuOpen;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: FocusableActionDetector(
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onOpen();
              return null;
            },
          ),
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: colors.base,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isCurrent
                  ? colors.accent.withValues(alpha: 0.6)
                  : _elevated
                  ? colors.accent.withValues(alpha: 0.45)
                  : colors.surface1,
              width: 1,
            ),
            boxShadow: _elevated
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: widget.onOpen,
                        onDoubleTap: widget.onRename,
                        onSecondaryTapDown: (details) =>
                            _showContextMenu(context, details.globalPosition),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            DocumentPreviewLoader(document: widget.document),
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 150),
                              opacity: _elevated ? 1 : 0,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
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
                                    child: _OpenPill(
                                      isCurrent: widget.isCurrent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: (_elevated || widget.isCurrent) ? 1 : 0,
                          child: IgnorePointer(
                            ignoring: !(_elevated || widget.isCurrent),
                            child: _CardMenuButton(
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
                          child: IgnorePointer(child: _CurrentBadge()),
                        ),
                    ],
                  ),
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onOpen,
                onDoubleTap: widget.onRename,
                onSecondaryTapDown: (details) =>
                    _showContextMenu(context, details.globalPosition),
                child: Padding(
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
                              style: theme.typography.inputText.copyWith(
                                fontWeight: FontWeight.w600,
                                fontSize: 14.5,
                                height: 1.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              formatLibraryEditedAt(widget.document.updatedAt),
                              style: theme.typography.hotkey.copyWith(
                                fontSize: 11.5,
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
                        color: _elevated
                            ? colors.text.withValues(alpha: 0.8)
                            : colors.subtext0.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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

class _OpenPill extends StatelessWidget {
  const _OpenPill({required this.isCurrent});

  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: theme.colors.text,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isCurrent ? Icons.bolt_rounded : Icons.north_east_rounded,
            size: 14,
            color: Colors.black87,
          ),
          const SizedBox(width: 6),
          Text(
            isCurrent ? 'Continue' : 'Open',
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrentBadge extends StatelessWidget {
  const _CurrentBadge();

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: theme.colors.accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Current',
            style: theme.typography.hotkey.copyWith(
              color: theme.colors.text,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _CardMenuButton extends StatefulWidget {
  const _CardMenuButton({
    required this.canDelete,
    required this.onRename,
    required this.onDelete,
    required this.onOpenChanged,
  });

  final bool canDelete;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final ValueChanged<bool> onOpenChanged;

  @override
  State<_CardMenuButton> createState() => _CardMenuButtonState();
}

class _CardMenuButtonState extends State<_CardMenuButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return LibraryMenuAnchor(
      menuWidth: 200,
      onOpenChanged: widget.onOpenChanged,
      menuItems: () => [
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
      buttonBuilder: (context, open, toggle) => MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: toggle,
          child: Tooltip(
            message: 'Document actions',
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.black.withValues(
                  alpha: _hovering || open ? 0.72 : 0.55,
                ),
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
              ),
              child: const Icon(
                Icons.more_horiz_rounded,
                size: 17,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
