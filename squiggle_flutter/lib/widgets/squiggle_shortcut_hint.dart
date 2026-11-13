import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// Adapts command-style shortcut notation (⌘, ⌃, ⌥, ⇧) to [platform]:
/// symbols on Apple platforms, `Ctrl+`-style words elsewhere.
String formatShortcut(String label, TargetPlatform platform) {
  final macStyle =
      platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
  if (macStyle) return label;
  return label
      .replaceAll('⌘', 'Ctrl+')
      .replaceAll('⌃', 'Ctrl+')
      .replaceAll('⌥', 'Alt+')
      .replaceAll('⇧', 'Shift+');
}

/// A subdued shortcut label. Command-style notation is adapted per platform.
class SquiggleShortcutHint extends StatelessWidget {
  const SquiggleShortcutHint({
    super.key,
    required this.label,
    this.enabled = true,
  });

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final formatted = formatShortcut(label, Theme.of(context).platform);
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        formatted,
        style: context.squiggleTheme.typography.menuItemLabel.copyWith(
          color: enabled ? context.squiggleTheme.colors.subtext0 : null,
        ),
      ),
    );
  }
}
