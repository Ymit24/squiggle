import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/editor/canvas_preferences.dart';
import 'package:squiggle_flutter/preferences/preferences.dart';
import 'package:squiggle_flutter/preferences/widgets/preference_row.dart';
import 'package:squiggle_flutter/preferences/widgets/preferences_section.dart';
import 'package:squiggle_flutter/widgets/squiggle_keycap.dart';
import 'package:squiggle_flutter/widgets/squiggle_switch.dart';

/// Editor canvas settings.
class CanvasSection extends StatelessWidget {
  const CanvasSection({super.key});

  @override
  Widget build(BuildContext context) {
    final showGrid = context.watchPreference(showGridPreference);
    void setShowGrid(bool value) =>
        context.read<Preferences>().set(showGridPreference, value);
    return PreferencesSection(
      title: 'Canvas',
      children: [
        PreferenceRow(
          title: 'Show grid',
          description: 'Guide lines behind the canvas',
          onTap: () => setShowGrid(!showGrid),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              const SquiggleKeycap(label: showGridShortcut),
              SquiggleSwitch(value: showGrid, onChanged: setShowGrid),
            ],
          ),
        ),
      ],
    );
  }
}
