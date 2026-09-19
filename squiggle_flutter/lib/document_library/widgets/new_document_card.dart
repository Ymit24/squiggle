import 'package:flutter/material.dart';
import 'package:squiggle_flutter/document_library/widgets/library_card_surface.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class NewDocumentCard extends StatelessWidget {
  const NewDocumentCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;

    return LibraryCardSurface(
      onPressed: onPressed,
      fillOnHighlight: true,
      showIdleShadow: false,
      semanticLabel: 'New canvas',
      builder: (context, highlighted) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: theme.motion.standard,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: highlighted
                  ? colors.text
                  : colors.surface0.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              boxShadow: highlighted
                  ? [
                      BoxShadow(
                        color: colors.text.withValues(alpha: 0.18),
                        blurRadius: 18,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              Icons.add_rounded,
              size: 28,
              color: highlighted ? Colors.black87 : colors.text,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'New canvas',
            style: theme.typography.cardTitle.copyWith(
              fontWeight: FontWeight.w700,
              color: highlighted
                  ? colors.text
                  : colors.text.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Start blank · ⌘N',
            style: theme.typography.caption.copyWith(
              color: highlighted
                  ? colors.subtext0
                  : colors.subtext0.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
