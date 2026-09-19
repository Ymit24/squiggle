import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_badge.dart';

class CurrentDocumentBadge extends StatelessWidget {
  const CurrentDocumentBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return SquiggleBadge(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      backgroundColor: Colors.black.withValues(alpha: 0.55),
      borderColor: theme.colors.accent.withValues(alpha: 0.5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: theme.colors.accent,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            'Current',
            style: theme.typography.hotkey.copyWith(
              color: theme.colors.text,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
