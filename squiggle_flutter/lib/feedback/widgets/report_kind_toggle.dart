import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:squiggle_flutter/feedback/feedback_report.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

/// Picks whether a report is a bug or an idea.
class ReportKindToggle extends StatelessWidget {
  const ReportKindToggle({
    super.key,
    required this.kind,
    required this.onChanged,
  });

  final FeedbackKind kind;
  final ValueChanged<FeedbackKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 8,
      children: [
        _option(FeedbackKind.bug, LucideIcons.bug, 'Bug'),
        _option(FeedbackKind.feature, LucideIcons.lightbulb, 'Idea'),
      ],
    );
  }

  Widget _option(FeedbackKind value, IconData icon, String label) {
    return SquiggleButton(
      onPressed: () => onChanged(value),
      icon: icon,
      label: label,
      variant: value == kind
          ? SquiggleButtonVariant.primary
          : SquiggleButtonVariant.secondary,
    );
  }
}
