import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle_dialog.dart';

/// Asked when leaving a canvas whose latest changes could not be saved.
/// Pops true to leave and lose them, false to keep editing.
class SaveFailedDialog extends StatelessWidget {
  const SaveFailedDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return SquiggleDialog(
      title: "Couldn't save this canvas",
      icon: Icons.report_gmailerrorred_rounded,
      iconColor: theme.colors.danger,
      content: Text(
        'Your latest changes could not be saved. If you leave now, they will '
        'be lost.',
        style: theme.typography.inputText.copyWith(
          color: theme.colors.subtext0,
          fontSize: 13.5,
          height: 1.45,
        ),
      ),
      actions: [
        SquiggleButton(
          onPressed: () => Navigator.of(context).pop(false),
          label: 'Keep editing',
          variant: SquiggleButtonVariant.ghost,
        ),
        SquiggleButton(
          onPressed: () => Navigator.of(context).pop(true),
          label: 'Leave without saving',
          variant: SquiggleButtonVariant.danger,
        ),
      ],
    );
  }
}
