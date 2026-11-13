import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:squiggle_flutter/preferences/preferences_panel.dart';

/// Toggles the preferences dialog with ⌘, or Ctrl+, from anywhere in [child].
class PreferencesShortcuts extends StatelessWidget {
  const PreferencesShortcuts({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    void toggle() => context.read<PreferencesPanel>().toggle();
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.comma, meta: true): toggle,
        const SingleActivator(LogicalKeyboardKey.comma, control: true): toggle,
      },
      child: child,
    );
  }
}
