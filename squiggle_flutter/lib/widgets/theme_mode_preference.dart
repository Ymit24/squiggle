import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:squiggle_flutter/database/app_database.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/widgets/preference_builder.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle_menu_item.dart';

/// Selects the theme mode stored in the database. Applying it is a later step.
class ThemeModePreference extends StatelessWidget {
  const ThemeModePreference({super.key});

  static const preferenceKey = 'themeMode';
  static const modes = ['system', 'light', 'dark'];

  @override
  Widget build(BuildContext context) {
    final database = context.read<AppDatabase>();
    return PreferenceBuilder(
      preferenceKey: preferenceKey,
      initialValue: 'system',
      builder: (context, value) {
        final mode = modes.contains(value) ? value! : 'system';
        return MenuAnchor(
          style: context.squiggleTheme.menuStyle(),
          menuChildren: [
            for (final option in modes)
              SquiggleMenuItem(
                label: _label(option),
                icon: _icon(option),
                checked: option == mode,
                onPressed: () =>
                    database.preferencesDao.setValue(preferenceKey, option),
              ),
          ],
          builder: (context, controller, _) => SquiggleButton(
            onPressed: controller.isOpen ? controller.close : controller.open,
            icon: Icons.brightness_6_rounded,
            label: 'Theme: ${_label(mode)}',
            variant: SquiggleButtonVariant.secondary,
          ),
        );
      },
    );
  }

  String _label(String mode) => switch (mode) {
    'light' => 'Light',
    'dark' => 'Dark',
    _ => 'System',
  };

  IconData _icon(String mode) => switch (mode) {
    'light' => Icons.light_mode_rounded,
    'dark' => Icons.dark_mode_rounded,
    _ => Icons.brightness_auto_rounded,
  };
}
