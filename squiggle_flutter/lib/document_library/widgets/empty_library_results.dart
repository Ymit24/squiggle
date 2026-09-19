import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_button.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_icon_tile.dart';

class EmptyLibraryResults extends StatelessWidget {
  const EmptyLibraryResults({
    super.key,
    required this.isSearching,
    required this.onClear,
    required this.onCreate,
  });

  final bool isSearching;
  final VoidCallback onClear;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      decoration: BoxDecoration(
        color: theme.colors.base,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colors.surface0),
      ),
      child: Column(
        children: [
          SquiggleIconTile(
            icon: isSearching
                ? Icons.search_off_rounded
                : Icons.dashboard_customize_outlined,
            size: 52,
            iconSize: 24,
            radius: 14,
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No canvases found' : 'No canvases yet',
            style: theme.typography.title,
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Try a different search term.'
                : 'Create your first canvas to get started.',
            style: theme.typography.body.copyWith(color: theme.colors.subtext0),
          ),
          const SizedBox(height: 18),
          if (isSearching)
            SquiggleButton(
              onPressed: onClear,
              label: 'Clear search',
              variant: SquiggleButtonVariant.ghost,
            )
          else
            SquiggleButton(
              onPressed: onCreate,
              icon: Icons.add_rounded,
              label: 'New canvas',
            ),
        ],
      ),
    );
  }
}
