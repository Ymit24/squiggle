import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_color_scheme.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class StyleColorSwatch extends StatefulWidget {
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

  @override
  State<StyleColorSwatch> createState() => _StyleColorSwatchState();

  bool _needsSubtleBorder(Color? color) {
    if (color == null) return false;
    return !isActive && color.computeLuminance() > 0.65;
  }
}

class _StyleColorSwatchState extends State<StyleColorSwatch> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    final spacing = theme.spacing;
    final colors = theme.colors;
    final opacity = widget.enabled ? 1.0 : 0.35;

    final Color borderColor;
    if (widget.isActive) {
      borderColor = colors.text;
    } else if (widget._needsSubtleBorder(widget.color)) {
      borderColor = colors.surface1;
    } else if (_hovering && widget.enabled) {
      borderColor = colors.subtext0;
    } else {
      borderColor = colors.surface1;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onPressed : null,
        behavior: HitTestBehavior.opaque,
        child: Opacity(
          opacity: opacity,
          child: SizedBox(
            width: spacing.swatchSize,
            height: spacing.swatchSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.color ?? colors.surface0,
                borderRadius: BorderRadius.circular(theme.radii.swatch),
                border: Border.all(
                  color: borderColor,
                  width: spacing.swatchBorderWidth,
                ),
              ),
              child: widget.overlay ?? _noneSwatchOverlay(colors),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _noneSwatchOverlay(SquiggleColorScheme colors) {
    if (widget.color != null) return null;
    return CustomPaint(
      painter: _NoneSwatchPainter(
        color: widget.isActive ? colors.text : colors.subtext0,
      ),
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
