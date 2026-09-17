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
  bool _focused = false;

  bool get _active => _hovering || _focused;

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
        child: FocusableActionDetector(
          onShowFocusHighlight: (value) => setState(() => _focused = value),
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onPressed();
                return null;
              },
            ),
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color: _active ? colors.surface0 : colors.base,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _active
                    ? colors.accent.withValues(alpha: 0.55)
                    : colors.surface1,
                width: 1,
              ),
              boxShadow: _active
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
                    color: _active
                        ? colors.text
                        : colors.surface0.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    boxShadow: _active
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
                    color: _active ? Colors.black87 : colors.text,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'New canvas',
                  style: theme.typography.inputText.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: _active
                        ? colors.text
                        : colors.text.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Start blank · ⌘N',
                  style: theme.typography.hotkey.copyWith(
                    fontSize: 11.5,
                    color: _active
                        ? colors.subtext0
                        : colors.subtext0.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
