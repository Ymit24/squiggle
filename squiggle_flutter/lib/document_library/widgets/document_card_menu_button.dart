import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu.dart';

class DocumentCardMenuButton extends StatefulWidget {
  const DocumentCardMenuButton({
    super.key,
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
  State<DocumentCardMenuButton> createState() => _DocumentCardMenuButtonState();
}

class _DocumentCardMenuButtonState extends State<DocumentCardMenuButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return LibraryMenuAnchor(
      menuWidth: 200,
      alignEnd: true,
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
