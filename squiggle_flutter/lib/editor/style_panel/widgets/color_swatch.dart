import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle/squiggle_pressable.dart';

class StyleColorSwatch extends StatelessWidget {
  const StyleColorSwatch({
    super.key,
    required this.color,
    required this.isActive,
    required this.onPressed,
    this.enabled = true,
    this.overlay,
  });

  const StyleColorSwatch.none({
    super.key,
    required this.isActive,
    required this.onPressed,
    this.enabled = true,
  }) : color = null,
       overlay = null;

  final Color? color;
  final bool isActive;
  final VoidCallback onPressed;
  final bool enabled;
  final Widget? overlay;

  bool _needsSubtleBorder(Color? color) {
    if (color == null) return false;
    return !isActive && color.computeLuminance() > 0.65;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final colors = theme.colors;
    final opacity = enabled ? 1.0 : 0.35;

    return SquigglePressable(
      onPressed: enabled ? onPressed : null,
      builder: (context, state) {
        final borderColor = isActive
            ? colors.text
            : (_needsSubtleBorder(color)
                  ? colors.surface1
                  : (state.hovered && enabled
                        ? colors.subtext0
                        : colors.surface1));
        return Opacity(
          opacity: opacity,
          child: SizedBox(
            width: spacing.swatchSize,
            height: spacing.swatchSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: color ?? colors.surface0,
                borderRadius: BorderRadius.circular(theme.radii.swatch),
                border: Border.all(
                  color: borderColor,
                  width: spacing.swatchBorderWidth,
                ),
              ),
              child:
                  overlay ??
                  (color == null
                      ? CustomPaint(
                          painter: _NoneSwatchPainter(
                            color: isActive ? colors.text : colors.subtext0,
                          ),
                        )
                      : null),
            ),
          ),
        );
      },
    );
  }
}

class _NoneSwatchPainter extends CustomPainter {
  const _NoneSwatchPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(5, 5),
      Offset(size.width - 5, size.height - 5),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _NoneSwatchPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
