import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_pressable.dart';

typedef LibraryCardBuilder =
    Widget Function(BuildContext context, bool highlighted);

class LibraryCardSurface extends StatelessWidget {
  const LibraryCardSurface({
    super.key,
    required this.onPressed,
    required this.builder,
    this.onDoubleTap,
    this.onSecondaryTapDown,
    this.isCurrent = false,
    this.fillOnHighlight = false,
    this.forceHighlighted = false,
    this.showIdleShadow = true,
    this.semanticLabel,
  });

  final VoidCallback onPressed;
  final VoidCallback? onDoubleTap;
  final GestureTapDownCallback? onSecondaryTapDown;
  final bool isCurrent;
  final bool fillOnHighlight;
  final bool forceHighlighted;
  final bool showIdleShadow;
  final String? semanticLabel;
  final LibraryCardBuilder builder;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final colors = theme.colors;
    return SquigglePressable(
      onPressed: onPressed,
      onDoubleTap: onDoubleTap,
      onSecondaryTapDown: onSecondaryTapDown,
      semanticLabel: semanticLabel,
      builder: (context, state) {
        final highlighted = state.highlighted || forceHighlighted;
        return AnimatedContainer(
          duration: theme.motion.standard,
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: fillOnHighlight && highlighted
                ? colors.surface0
                : colors.base,
            borderRadius: BorderRadius.circular(theme.radii.card),
            border: Border.all(
              color: isCurrent
                  ? colors.accent.withValues(alpha: 0.6)
                  : highlighted
                  ? colors.accent.withValues(alpha: 0.45)
                  : colors.surface1,
            ),
            boxShadow: highlighted
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 28,
                      offset: const Offset(0, 14),
                    ),
                    BoxShadow(
                      color: colors.accent.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : showIdleShadow
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.28),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: builder(context, highlighted),
        );
      },
    );
  }
}
