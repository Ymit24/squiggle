import 'package:flutter/material.dart';
import 'package:squiggle_flutter/theme/squiggle_color_scheme.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';
import 'package:squiggle_flutter/widgets/squiggle_tooltip.dart';

class StyleColorSwatch extends StatefulWidget {
  const StyleColorSwatch({
    super.key,
    required this.color,
    required this.tooltip,
    this.tooltipDetail,
    required this.isActive,
    required this.onPressed,
    this.enabled = true,
    this.selectable = true,
    this.overlay,
  });

  const StyleColorSwatch.none({
    super.key,
    this.tooltip = 'None',
    required this.isActive,
    required this.onPressed,
    this.enabled = true,
  }) : color = null,
       tooltipDetail = null,
       selectable = true,
       overlay = null;

  final Color? color;

  /// Name of the option, shown on hover and used as its accessible label.
  final String tooltip;

  /// Subdued extra detail in the tooltip, such as a hex value.
  final String? tooltipDetail;

  /// Whether this swatch picks an option (exposed as selected) rather than
  /// running a one-off action.
  final bool selectable;
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
    return Semantics(
      button: true,
      enabled: widget.enabled,
      selected: widget.selectable ? widget.isActive : null,
      label: widget.tooltip,
      child: SquiggleTooltip(
        label: widget.tooltip,
        detail: widget.tooltipDetail,
        child: _buildSwatch(theme),
      ),
    );
  }

  Widget _buildSwatch(SquiggleTheme theme) {
    final spacing = theme.spacing;
    final colors = theme.colors;
    final opacity = widget.enabled ? 1.0 : 0.35;
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
                  color: _borderColor(colors),
                  width: spacing.swatchBorderWidth,
                ),
              ),
              child: ExcludeSemantics(
                child: widget.overlay ?? _noneSwatchOverlay(colors),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _borderColor(SquiggleColorScheme colors) {
    if (widget.isActive) {
      return colors.text;
    }
    if (widget._needsSubtleBorder(widget.color)) {
      return colors.surface1;
    }
    if (_hovering && widget.enabled) {
      return colors.subtext0;
    }
    return colors.surface1;
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
