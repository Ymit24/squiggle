import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

const swatchSize = 26.0;
const swatchGap = 6.0;
const swatchRadius = 5.0;
const swatchBorderWidth = 2.0;

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

  bool get _needsSubtleBorder {
    final color = this.color;
    if (color == null) return false;
    return !isActive && color.computeLuminance() > 0.65;
  }

  @override
  State<StyleColorSwatch> createState() => _StyleColorSwatchState();
}

class _StyleColorSwatchState extends State<StyleColorSwatch> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final opacity = widget.enabled ? 1.0 : 0.35;
    final borderColor = widget.isActive
        ? SquiggleColors.text
        : (widget._needsSubtleBorder
              ? SquiggleColors.surface1
              : (_hovering && widget.enabled
                    ? SquiggleColors.subtext0
                    : SquiggleColors.surface1));

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
            width: swatchSize,
            height: swatchSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: widget.color ?? SquiggleColors.surface0,
                borderRadius: BorderRadius.circular(swatchRadius),
                border: Border.all(
                  color: borderColor,
                  width: swatchBorderWidth,
                ),
              ),
              child:
                  widget.overlay ??
                  (widget.color == null
                      ? CustomPaint(
                          painter: _NoneSwatchPainter(
                            color: widget.isActive
                                ? SquiggleColors.text
                                : SquiggleColors.subtext0,
                          ),
                        )
                      : null),
            ),
          ),
        ),
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
