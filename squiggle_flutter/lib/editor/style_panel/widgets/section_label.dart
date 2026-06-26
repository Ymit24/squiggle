import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: theme.spacing.panelLabelSpacing),
      child: Text(
        label,
        style: theme.typography.sectionLabel,
      ),
    );
  }
}
