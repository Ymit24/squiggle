import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/preferences/preferences.dart';
import 'package:squiggle_flutter/preferences/widgets/preference_row.dart';
import 'package:squiggle_flutter/preferences/widgets/preferences_section.dart';
import 'package:squiggle_flutter/theme/theme_mode_preference.dart';
import 'package:squiggle_flutter/widgets/squiggle_segmented_control.dart';

/// Theme choice: follow the system, or force light or dark.
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  static const _segments = [
    SquiggleSegment(
      value: ThemeMode.system,
      label: 'System',
      icon: LucideIcons.monitor,
    ),
    SquiggleSegment(
      value: ThemeMode.light,
      label: 'Light',
      icon: LucideIcons.sun,
    ),
    SquiggleSegment(
      value: ThemeMode.dark,
      label: 'Dark',
      icon: LucideIcons.moon,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return PreferencesSection(
      title: 'Appearance',
      children: [
        PreferenceRow(
          title: 'Theme',
          trailing: SquiggleSegmentedControl(
            segments: _segments,
            selected: context.watchPreference(themeModePreference),
            onChanged: (mode) =>
                context.read<Preferences>().set(themeModePreference, mode),
          ),
        ),
      ],
    );
  }
}
