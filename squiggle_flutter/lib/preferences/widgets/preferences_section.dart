import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// A titled group of [PreferenceRow]s, drawn as one raised card with thin
/// gaps between rows.
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
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: theme.spacing.panelPadding,
            bottom: theme.spacing.panelLabelSpacing,
          ),
          child: Semantics(
            header: true,
            child: Text(title, style: theme.typography.sectionLabel),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
          child: ColoredBox(
            color: theme.colors.surface0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, child) in children.indexed) ...[
                  if (index > 0)
                    Divider(height: 1, thickness: 1, color: theme.colors.base),
                  child,
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
