import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// A compact row of mutually exclusive choices, sized to its labels.
///
/// The track is recessed in `base`, so it reads as one control on a raised
/// `surface0` card; the selected segment is raised in `surface1`.
class SquiggleSegmentedControl<T> extends StatelessWidget {
  const SquiggleSegmentedControl({
    super.key,
    required this.segments,
    required this.selected,
    required this.onChanged,
  });

  final List<SquiggleSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    const inset = 3.0;
    return Container(
      padding: const EdgeInsets.all(inset),
      decoration: BoxDecoration(
        color: theme.colors.base,
        borderRadius: BorderRadius.circular(theme.radii.button + inset),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: theme.spacing.toolbarGap,
        children: [for (final segment in segments) _segment(theme, segment)],
      ),
    );
  }

  Widget _segment(SquiggleTheme theme, SquiggleSegment<T> segment) {
    final isSelected = segment.value == selected;
    return MergeSemantics(
      child: Semantics(
        inMutuallyExclusiveGroup: true,
        selected: isSelected,
        child: TextButton(
          onPressed: () => onChanged(segment.value),
          style: _style(theme, isSelected),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 6,
            children: [
              if (segment.icon != null) Icon(segment.icon, size: 14),
              Text(segment.label),
            ],
          ),
        ),
      ),
    );
  }

  ButtonStyle _style(SquiggleTheme theme, bool isSelected) {
    final colors = theme.colors;
    return TextButton.styleFrom(
      foregroundColor: isSelected ? colors.text : colors.subtext0,
      textStyle: theme.typography.menuItemLabel.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      minimumSize: Size(0, theme.spacing.menuItemHeight),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.standard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(theme.radii.button),
      ),
      splashFactory: NoSplash.splashFactory,
    ).copyWith(
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (isSelected) return colors.surface1;
        if (states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused)) {
          return colors.surface1.withValues(alpha: 0.4);
        }
        return Colors.transparent;
      }),
    );
  }
}

/// One choice in a [SquiggleSegmentedControl].
@immutable
class SquiggleSegment<T> {
  const SquiggleSegment({required this.value, required this.label, this.icon});

  final T value;
  final String label;
  final IconData? icon;
}
