import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// One setting inside a `PreferencesSection`: a title with an optional
/// description on the left and its [trailing] control on the right.
///
/// [onTap] makes the whole row a click target for its control. The row itself
/// takes no focus; keyboard users reach the [trailing] control instead.
class PreferenceRow extends StatelessWidget {
  const PreferenceRow({
    super.key,
    required this.title,
    this.description,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return MergeSemantics(
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: theme.colors.surface1.withValues(alpha: 0.4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: theme.spacing.panelPadding,
                vertical: 10,
              ),
              child: Row(
                spacing: theme.spacing.panelPadding,
                children: [
                  Expanded(child: _label(theme)),
                  ?trailing,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(SquiggleTheme theme) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 2,
    children: [
      Text(title, style: theme.typography.inputText),
      if (description != null)
        Text(
          description!,
          style: theme.typography.tooltip.copyWith(
            color: theme.colors.subtext0,
          ),
        ),
    ],
  );
}
