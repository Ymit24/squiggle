import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_badge.dart';

class LibrarySectionHeader extends StatelessWidget {
  const LibrarySectionHeader({
    super.key,
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Row(
      children: [
        Text(
          title,
          style: theme.typography.inputText.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
            color: theme.colors.subtext0,
          ),
        ),
        const SizedBox(width: 8),
        SquiggleBadge(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          borderColor: theme.colors.surface1,
          child: Text(
            '$count',
            style: theme.typography.hotkey.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: theme.colors.surface0, thickness: 1)),
      ],
    );
  }
}
