import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_pill.dart';

class CurrentDocumentBadge extends StatelessWidget {
  const CurrentDocumentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return SquigglePill(
      label: 'Current',
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      backgroundColor: Colors.black.withValues(alpha: 0.55),
      borderColor: theme.colors.accent.withValues(alpha: 0.5),
      textStyle: theme.typography.hotkey.copyWith(
        color: theme.colors.text,
        fontSize: 10.5,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      leading: Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: theme.colors.accent,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
