import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:squiggle_flutter/feedback/widgets/report_dialog.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

/// Opens the bug report / idea dialog.
class ReportButton extends StatelessWidget {
  const ReportButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SquiggleButton(
      onPressed: () => showReportDialog(context),
      icon: LucideIcons.messageSquarePlus,
      label: 'Report a bug or idea',
      variant: SquiggleButtonVariant.secondary,
      compact: true,
    );
  }
}
