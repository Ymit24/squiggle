import 'package:flutter/material.dart';
import 'package:squiggle_flutter/models/document_info.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle_dialog.dart';

class DeleteDocumentDialog extends StatelessWidget {
  const DeleteDocumentDialog({super.key, required this.document});

  final DocumentInfo document;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return SquiggleDialog(
      title: 'Delete canvas?',
      icon: Icons.delete_outline_rounded,
      iconColor: theme.colors.danger,
      content: Text(
        '"${document.name}" will be permanently deleted. This cannot be undone.',
        style: theme.typography.inputText.copyWith(
          color: theme.colors.subtext0,
          fontSize: 13.5,
          height: 1.45,
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
