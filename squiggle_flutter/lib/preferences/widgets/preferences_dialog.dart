import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:squiggle_flutter/preferences/widgets/about_section.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle_dialog.dart';
import 'package:squiggle_flutter/widgets/squiggle_shortcut_hint.dart';

/// Shortcut that opens and closes the preferences dialog.
const preferencesShortcut = '⌘,';

/// App-wide settings. Changes apply as soon as they are made.
///
/// To add a setting, declare a `Preference` beside the feature that reads it
/// and add a `PreferencesSection` holding its control to [_sections].
class PreferencesDialog extends StatelessWidget {
  const PreferencesDialog({super.key});

  static const _sections = <Widget>[AboutSection()];

  @override
  Widget build(BuildContext context) {
    return SquiggleDialog(
      title: 'Preferences',
      icon: LucideIcons.settings,
      titleTrailing: const SquiggleShortcutHint(label: preferencesShortcut),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 18,
          children: _sections,
        ),
      ),
      actions: [
        SquiggleButton(
          onPressed: () => Navigator.of(context).pop(),
          label: 'Done',
        ),
      ],
    );
  }
}
