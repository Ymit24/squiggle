import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_button.dart';

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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: theme.colors.surface0,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.colors.surface1),
            ),
            child: Icon(
              isSearching
                  ? Icons.search_off_rounded
                  : Icons.dashboard_customize_outlined,
              size: 24,
              color: theme.colors.subtext0,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isSearching ? 'No canvases found' : 'No canvases yet',
            style: theme.typography.inputText.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSearching
                ? 'Try a different search term.'
                : 'Create your first canvas to get started.',
            style: theme.typography.inputText.copyWith(
              color: theme.colors.subtext0,
              fontSize: 13.5,
            ),
          ),
          const SizedBox(height: 18),
          if (isSearching)
            SquiggleButton(
              label: 'Clear search',
              variant: SquiggleButtonVariant.ghost,
              onPressed: onClear,
            )
          else
            SquiggleButton(
              label: 'New canvas',
              leading: const Icon(Icons.add_rounded),
              variant: SquiggleButtonVariant.primary,
              onPressed: onCreate,
            ),
        ],
      ),
    );
  }
}
