import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_content.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu_item.dart';
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
    final colors = context.squiggleTheme.colors;
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

    return PopupMenuButton<LibraryMenuItem>(
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      tooltip: 'Document actions',
      icon: const Icon(Icons.more_horiz_rounded),
      iconSize: context.squiggleTheme.spacing.buttonIconSize,
      style: context.squiggleTheme.buttonStyle(
        variant: SquiggleButtonVariant.secondary,
        compact: true,
      ),
      color: colors.surface0,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black,
      elevation: 16,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colors.surface1),
      ),
      menuPadding: const EdgeInsets.all(6),
      constraints: const BoxConstraints.tightFor(width: 200),
      onOpened: () => onOpenChanged(true),
      onCanceled: () => onOpenChanged(false),
      onSelected: (item) {
        onOpenChanged(false);
        item.onTap();
      },
      itemBuilder: (_) => [
        for (final item in items)
          PopupMenuItem<LibraryMenuItem>(
            value: item,
            height: 40,
            padding: EdgeInsets.zero,
            child: LibraryMenuContent(item: item),
          ),
      ],
    );
  }
}
