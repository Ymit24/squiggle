import 'package:flutter/material.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_dialog.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_icon_tile.dart';

class DeleteDocumentDialog extends StatelessWidget {
  const DeleteDocumentDialog({super.key, required this.document});

  final DocumentInfo document;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return SquiggleDialog(
      title: Row(
        children: [
          const SquiggleIconTile(
            icon: Icons.delete_outline_rounded,
            size: 36,
            iconSize: 19,
            tone: SquiggleIconTileTone.danger,
          ),
          const SizedBox(width: 12),
          Text('Delete canvas?', style: theme.typography.title),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Text(
          '"${document.name}" will be permanently deleted. This cannot be undone.',
          style: theme.typography.body.copyWith(
            color: theme.colors.subtext0,
            height: 1.45,
          ),
        ),
      ),
      actions: [
        SquiggleButton(
          onPressed: () => Navigator.of(context).pop(false),
          label: 'Cancel',
          variant: SquiggleButtonVariant.ghost,
        ),
        SquiggleButton(
          onPressed: () => Navigator.of(context).pop(true),
          label: 'Delete',
          variant: SquiggleButtonVariant.danger,
        ),
      ],
    );
  }
}
