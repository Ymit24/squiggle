import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// A subdued shortcut label. Command-style notation is adapted per platform.
class SquiggleShortcutHint extends StatelessWidget {
  const SquiggleShortcutHint({
    super.key,
    required this.label,
    this.enabled = true,
    this.compact = false,
  });

  final String label;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final macStyle =
        platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
    final formatted = macStyle
        ? label
        : label
              .replaceAll('⌘', 'Ctrl+')
              .replaceAll('⌃', 'Ctrl+')
              .replaceAll('⌥', 'Alt+')
              .replaceAll('⇧', 'Shift+');
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        formatted,
        style: TextStyle(
          fontSize: compact ? 11 : null,
          color: enabled ? context.squiggleTheme.colors.subtext0 : null,
        ),
      ),
    );
  }
}
