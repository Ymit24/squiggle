import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:squiggle_flutter/preferences/widgets/about_section.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle_dialog.dart';

/// Shortcut that opens and closes the preferences dialog.
const preferencesShortcut = '⌘,';

/// App-wide settings. Changes apply as soon as they are made, so the dialog
/// only needs a close button.
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
      contentWidth: 440,
      titleTrailing: SquiggleButton(
        onPressed: () => Navigator.of(context).pop(),
        icon: LucideIcons.x,
        label: 'Close',
        shortcuts: const ['Esc', preferencesShortcut],
        variant: SquiggleButtonVariant.ghost,
        compact: true,
      ),
      content: const SingleChildScrollView(
        padding: EdgeInsets.only(top: 6, bottom: 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 20,
          children: _sections,
        ),
      ),
    );
  }
}
