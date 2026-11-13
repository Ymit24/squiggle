import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/preferences/preferences_panel.dart';
import 'package:squiggle_flutter/preferences/widgets/preferences_dialog.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

/// Compact gear button that opens the preferences dialog.
class PreferencesButton extends StatelessWidget {
  const PreferencesButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SquiggleButton(
      onPressed: () => context.read<PreferencesPanel>().open(),
      icon: LucideIcons.settings,
      label: 'Preferences',
      shortcuts: const [preferencesShortcut],
      variant: SquiggleButtonVariant.secondary,
      compact: true,
    );
  }
}
