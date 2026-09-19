import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_menu.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_pressable.dart';

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
    final theme = context.squiggleTheme;
    return LibraryMenuAnchor(
      menuWidth: 200,
      onOpenChanged: onOpenChanged,
      menuItems: () => [
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
      ],
      buttonBuilder: (context, open, toggle) => SquigglePressable(
        onPressed: toggle,
        semanticLabel: 'Document actions',
        builder: (context, state) => Tooltip(
          message: 'Document actions',
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Colors.black.withValues(
                alpha: state.highlighted || open ? 0.72 : 0.55,
              ),
              borderRadius: BorderRadius.circular(theme.radii.action),
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
    );
  }
}
