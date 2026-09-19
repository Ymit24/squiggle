import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_pressable.dart';

class EditorBackButton extends StatelessWidget {
  const EditorBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;
    return SquigglePressable(
      onPressed: onPressed,
      semanticLabel: 'Back to canvas library',
      builder: (context, state) => DecoratedBox(
        decoration: BoxDecoration(
          color: state.highlighted
              ? colors.surface0.withValues(alpha: 0.85)
              : colors.mantle,
          border: Border.all(color: colors.surface1),
          borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Icon(
            Icons.grid_view_rounded,
            size: 16,
            color: state.highlighted ? colors.text : colors.subtext0,
          ),
        ),
      ),
    );
  }
}
