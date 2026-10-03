import 'package:flutter/material.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle_dialog.dart';

class DeleteBrushDialog extends StatelessWidget {
  const DeleteBrushDialog({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) => SquiggleDialog(
    title: 'Delete brush?',
    icon: Icons.delete_outline,
    content: Text('Delete "$name"? Existing objects will keep their styles.'),
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
