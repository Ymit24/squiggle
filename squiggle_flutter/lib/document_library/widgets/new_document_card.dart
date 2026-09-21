import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_pressable.dart';

class NewDocumentCard extends StatelessWidget {
  const NewDocumentCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;

    return SquigglePressable(
      onPressed: onPressed,
      builder: (context, state) => AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: state.isHighlighted ? colors.surface0 : colors.base,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: state.isHighlighted
                ? colors.accent.withValues(alpha: 0.55)
                : colors.surface1,
            width: 1,
          ),
          boxShadow: state.isHighlighted
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: state.isHighlighted
                    ? colors.text
                    : colors.surface0.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                boxShadow: state.isHighlighted
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
                color: state.isHighlighted ? Colors.black87 : colors.text,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'New canvas',
              style: theme.typography.inputText.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: state.isHighlighted
                    ? colors.text
                    : colors.text.withValues(alpha: 0.85),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Start blank · ⌘N',
              style: theme.typography.hotkey.copyWith(
                fontSize: 11.5,
                color: state.isHighlighted
                    ? colors.subtext0
                    : colors.subtext0.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
