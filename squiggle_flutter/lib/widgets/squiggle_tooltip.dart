import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_shortcut_hint.dart';

/// Hover tooltip naming a control and, optionally, its keyboard shortcuts
/// or another short detail (such as a colour's hex value).
///
/// Appearance, placement and hover delay come from the app's
/// [TooltipThemeData]; shortcuts use the same platform-adapted notation as
/// [SquiggleShortcutHint], so pass them in command-style form (`⌘Z`).
class SquiggleTooltip extends StatelessWidget {
  const SquiggleTooltip({
    super.key,
    required this.label,
    this.shortcuts = const [],
    this.detail,
    required this.child,
  });

  final String label;
  final List<String> shortcuts;

  /// Subdued text after [label], shown after any [shortcuts].
  final String? detail;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final typography = context.squiggleTheme.typography;
    final secondary = [
      for (final shortcut in shortcuts) formatShortcut(shortcut, platform),
      ?detail,
    ];
    return Tooltip(
      richMessage: TextSpan(
        text: label,
        style: typography.tooltip,
        children: [
          if (secondary.isNotEmpty)
            TextSpan(
              text: '  ${secondary.join(' · ')}',
              style: typography.tooltipShortcut,
            ),
        ],
      ),
      child: child,
    );
  }
}
