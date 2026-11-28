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
              child: Stack(
                children: [
                  Column(
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
                  Positioned(
                    top: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                      iconSize: 14,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 20,
                        height: 20,
                      ),
                      splashRadius: 12,
                      color: theme.colors.subtext0,
                      hoverColor: theme.colors.surface0,
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
