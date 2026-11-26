import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/widgets/preference_builder.dart';

/// Selects the theme mode stored in the database. Applying it is a later step.
class ThemeModePreference extends StatelessWidget {
  const ThemeModePreference({super.key});

  static const preferenceKey = 'themeMode';
  static const modes = [
    (value: 'system', label: 'System'),
    (value: 'light', label: 'Light'),
    (value: 'dark', label: 'Dark'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final database = context.read<AppDatabase>();
    return PreferenceBuilder(
      preferenceKey: preferenceKey,
      initialValue: 'system',
      builder: (context, value) {
        final selected = modes.any((mode) => mode.value == value)
            ? value!
            : 'system';
        return SizedBox(
          width: double.infinity,
          child: SegmentedButton<String>(
            segments: [
              for (final mode in modes)
                ButtonSegment(value: mode.value, label: Text(mode.label)),
            ],
            selected: {selected},
            showSelectedIcon: false,
            style: _style(theme),
            onSelectionChanged: (selection) =>
                database.preferencesDao.setValue(preferenceKey, selection.first),
          ),
        );
      },
    );
  }

  ButtonStyle _style(SquiggleTheme theme) {
    final colors = theme.colors;
    return ButtonStyle(
      splashFactory: NoSplash.splashFactory,
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      minimumSize: WidgetStatePropertyAll(Size(0, theme.spacing.buttonHeight)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: theme.spacing.menuPadding),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textStyle: WidgetStatePropertyAll(
        theme.typography.menuItemLabel.copyWith(fontSize: 12),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(theme.radii.button),
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? colors.surface0 : colors.base,
      ),
      foregroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.selected) ? colors.text : colors.subtext0,
      ),
      side: WidgetStatePropertyAll(BorderSide(color: colors.surface1)),
    );
  }
}
