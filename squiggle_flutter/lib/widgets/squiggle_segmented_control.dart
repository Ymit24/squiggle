import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

/// A row of mutually exclusive choices sharing the width equally.
///
/// Segments use the toolbar button states: `surface1` when selected and
/// `surface0` on hover, inside a floating-panel style track.
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
    final inset = theme.spacing.toolbarPadding;
    return Container(
      padding: EdgeInsets.all(inset),
      decoration: BoxDecoration(
        color: theme.colors.mantle,
        border: Border.all(color: theme.colors.surface1),
        borderRadius: BorderRadius.circular(theme.radii.button + inset),
      ),
      child: Row(
        spacing: theme.spacing.toolbarGap,
        children: [
          for (final segment in segments)
            Expanded(child: _segment(theme, segment)),
        ],
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
            spacing: theme.spacing.buttonIconGap,
            children: [
              if (segment.icon != null)
                Icon(segment.icon, size: theme.spacing.buttonIconSize - 2),
              Flexible(child: Text(segment.label, overflow: TextOverflow.fade)),
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
      textStyle: theme.typography.actionButtonLabel.copyWith(
        fontWeight: FontWeight.w600,
      ),
      minimumSize: Size(0, theme.spacing.toolbarButtonSize),
      padding: const EdgeInsets.symmetric(horizontal: 8),
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
          return colors.surface0;
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
