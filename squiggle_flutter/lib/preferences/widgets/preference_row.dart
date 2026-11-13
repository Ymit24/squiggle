import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// One setting in the preferences dialog: an icon, a title with an optional
/// description, and a [trailing] control.
///
/// [onTap] makes the whole row a click target for its control. The row itself
/// takes no focus; keyboard users reach the [trailing] control instead.
class PreferenceRow extends StatelessWidget {
  const PreferenceRow({
    super.key,
    required this.icon,
    required this.title,
    this.description,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? description;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;
    final radius = BorderRadius.circular(theme.radii.floatingPanel);
    return MergeSemantics(
      child: Material(
        color: colors.mantle,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: colors.surface1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          canRequestFocus: false,
          splashFactory: NoSplash.splashFactory,
          highlightColor: Colors.transparent,
          hoverColor: colors.surface0,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: theme.spacing.panelPadding,
              vertical: 10,
            ),
            child: Row(
              spacing: theme.spacing.panelPadding,
              children: [
                Icon(
                  icon,
                  size: theme.spacing.buttonIconSize,
                  color: colors.subtext0,
                ),
                Expanded(child: _label(theme)),
                ?trailing,
              ],
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
