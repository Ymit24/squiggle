import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_anchor.dart';
import 'package:squiggle_flutter/theme/squiggle_button_style.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class DocumentCardMenuButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final items = [
      LibraryMenuItem(
        label: 'Rename',
        icon: Icons.drive_file_rename_outline,
        onTap: onRename,
      ),
      if (canDelete)
        LibraryMenuItem(
          label: 'Delete',
          icon: Icons.delete_outline_rounded,
          danger: true,
          onTap: onDelete,
        ),
    ];

    return LibraryMenuAnchor(
      menuItems: () => items,
      onOpenChanged: onOpenChanged,
      buttonBuilder: (context, open, toggle) => IconButton(
        onPressed: toggle,
        tooltip: 'Document actions',
        icon: const Icon(Icons.more_horiz_rounded),
        iconSize: context.squiggleTheme.spacing.buttonIconSize,
        style: context.squiggleTheme.buttonStyle(
          variant: SquiggleButtonVariant.secondary,
          compact: true,
        ),
      ),
    );
  }
}
