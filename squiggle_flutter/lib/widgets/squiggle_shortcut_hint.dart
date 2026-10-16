import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';

/// A subdued shortcut label. Command-style notation is adapted per platform.
class SquiggleShortcutHint extends StatelessWidget {
  const SquiggleShortcutHint({
    super.key,
    required this.label,
    this.enabled = true,
    this.style,
    this.alignment = Alignment.centerRight,
  });

  final String label;
  final bool enabled;

  /// Replaces the default menu item text style.
  final TextStyle? style;

  /// Where the text sits when it is scaled down to fit a narrower parent.
  final AlignmentGeometry alignment;

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
      alignment: alignment,
      child: Text(
        formatted,
        style:
            style ??
            context.squiggleTheme.typography.menuItemLabel.copyWith(
              color: enabled ? context.squiggleTheme.colors.subtext0 : null,
            ),
      ),
    );
  }
}
