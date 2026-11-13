import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_shortcut_hint.dart';

/// A shortcut drawn as a small key, for hints that sit beside a control
/// rather than in a menu. Command-style notation is adapted per platform.
class SquiggleKeycap extends StatelessWidget {
  const SquiggleKeycap({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colors.surface1,
        borderRadius: BorderRadius.circular(theme.radii.swatch),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Text(
          formatShortcut(label, Theme.of(context).platform),
          style: theme.typography.hotkey.copyWith(fontSize: 10),
        ),
      ),
    );
  }
}
