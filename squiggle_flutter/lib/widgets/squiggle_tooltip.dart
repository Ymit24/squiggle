import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_shortcut_hint.dart';

/// Hover tooltip naming a control and, optionally, its keyboard shortcuts.
///
/// Appearance, placement and hover delay come from the app's
/// [TooltipThemeData]; shortcuts use the same platform-adapted notation as
/// [SquiggleShortcutHint], so pass them in command-style form (`⌘Z`).
class SquiggleTooltip extends StatelessWidget {
  const SquiggleTooltip({
    super.key,
    required this.label,
    this.shortcuts = const [],
    required this.child,
  });

  final String label;
  final List<String> shortcuts;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final typography = context.squiggleTheme.typography;
    return Tooltip(
      richMessage: TextSpan(
        text: label,
        style: typography.tooltip,
        children: [
          if (shortcuts.isNotEmpty)
            TextSpan(
              text:
                  '  ${shortcuts.map((s) => formatShortcut(s, platform)).join(' · ')}',
              style: typography.tooltipShortcut,
            ),
        ],
      ),
      child: child,
    );
  }
}
