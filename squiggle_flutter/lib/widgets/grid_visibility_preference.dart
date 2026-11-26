import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/preference_builder.dart';
import 'package:squiggle_flutter/widgets/squiggle_switch.dart';

/// Toggles the world-space grid drawn behind the editor canvas.
class GridVisibilityPreference extends StatelessWidget {
  const GridVisibilityPreference({super.key});

  static const preferenceKey = 'grid-lines-visible';

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final colors = theme.colors;
    final database = context.read<AppDatabase>();

    return PreferenceBuilder(
      preferenceKey: preferenceKey,
      initialValue: 'true',
      builder: (context, value) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(theme.radii.button),
          border: Border.all(color: colors.surface1),
        ),
        child: Padding(
          padding: EdgeInsets.all(spacing.menuPadding),
          child: Row(
            children: [
              Icon(
                Icons.grid_view_rounded,
                size: spacing.toolbarIconSize,
                color: colors.subtext0,
              ),
              SizedBox(width: spacing.menuPadding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Show grid',
                      style: theme.typography.menuItemLabel.copyWith(
                        color: colors.text,
                      ),
                    ),
                    Text(
                      'Guide lines behind the canvas',
                      style: theme.typography.menuItemLabel.copyWith(
                        color: colors.subtext0,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              SquiggleSwitch(
                value: value != 'false',
                onChanged: (visible) =>
                    database.preferencesDao.setValue(preferenceKey, '$visible'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
