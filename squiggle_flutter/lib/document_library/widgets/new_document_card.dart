import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class NewDocumentCard extends StatefulWidget {
  const NewDocumentCard({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<NewDocumentCard> createState() => _NewDocumentCardState();
}

class _NewDocumentCardState extends State<NewDocumentCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _hovering
                ? colors.surface0.withValues(alpha: 0.35)
                : colors.mantle.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(theme.radii.floatingPanel),
            border: Border.all(
              color: _hovering ? colors.accent.withValues(alpha: 0.55) : colors.surface1,
              width: _hovering ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: _hovering ? 0.18 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(Icons.add, size: 28),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'New document',
                style: theme.typography.inputText.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _hovering ? colors.text : colors.subtext0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Start with a blank canvas',
                style: theme.typography.hotkey.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
