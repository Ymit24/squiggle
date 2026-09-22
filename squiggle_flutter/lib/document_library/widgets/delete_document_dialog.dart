import 'package:flutter/material.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

class DeleteDocumentDialog extends StatelessWidget {
  const DeleteDocumentDialog({super.key, required this.document});

  final DocumentInfo document;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return AlertDialog(
      backgroundColor: theme.colors.base,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colors.surface1),
      ),
      titlePadding: const EdgeInsets.fromLTRB(22, 20, 22, 0),
      contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
      actionsPadding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.delete_outline_rounded,
              size: 19,
              color: theme.colors.danger,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Delete canvas?',
            style: theme.typography.inputText.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 340,
        child: Text(
          '"${document.name}" will be permanently deleted. This cannot be undone.',
          style: theme.typography.inputText.copyWith(
            color: theme.colors.subtext0,
            fontSize: 13.5,
            height: 1.45,
          ),
        ),
      ),
      actions: [
        SquiggleButton(
          label: 'Cancel',
          variant: SquiggleButtonVariant.ghost,
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        SquiggleButton(
          label: 'Delete',
          variant: SquiggleButtonVariant.danger,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
