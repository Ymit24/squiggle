import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// Shows the preferences panel as a modal dialog layered on top of the app.
Future<void> showPreferencesPanel(BuildContext context) {
  return showDialog<void>(
    context: context,
    builder: (context) => const PreferencesPanel(),
  );
}

/// Empty preferences panel dialog.
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
        height: 160,
        child: DecoratedBox(
          decoration: theme.decorations.floatingPanel(),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
            child: Padding(
              padding: EdgeInsets.all(spacing.panelPadding),
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }
}
