import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// A titled group of controls in the preferences dialog.
class PreferencesSection extends StatelessWidget {
  const PreferencesSection({
    super.key,
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: theme.spacing.panelLabelSpacing,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: theme.typography.sectionLabel),
        ),
        ...children,
      ],
    );
  }
}
