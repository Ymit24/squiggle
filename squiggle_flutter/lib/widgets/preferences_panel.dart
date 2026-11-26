import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/grid_visibility_preference.dart';
import 'package:squiggle_flutter/widgets/theme_mode_preference.dart';

/// Settings dialog holding user preferences.
class PreferencesPanel extends StatelessWidget {
  const PreferencesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: SizedBox(
        width: spacing.menuWidth,
        child: DecoratedBox(
          decoration: theme.decorations.floatingPanel(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
            child: Padding(
              padding: EdgeInsets.all(spacing.panelPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: spacing.panelSectionSpacing,
                children: [
                  Text('Appearance', style: theme.typography.sectionLabel),
                  const ThemeModePreference(),
                  Text('Canvas', style: theme.typography.sectionLabel),
                  const GridVisibilityPreference(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
