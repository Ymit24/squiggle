import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/style_panel/style_presets.dart';
import 'package:squiggle_flutter/editor/style_panel/widgets/color_swatch.dart';
import 'package:squiggle_flutter/theme/squiggle_colors.dart';

/// Icon bar height in the width picker (not the canvas stroke width).
double _previewBarHeight(StrokeWidthPreset preset) => switch (preset) {
  StrokeWidthPreset.thin => 2,
  StrokeWidthPreset.medium => 5,
  StrokeWidthPreset.thick => 9,
};

class StrokeWidthSelector extends StatelessWidget {
  const StrokeWidthSelector({
    super.key,
    required this.activePreset,
    required this.isMixed,
    required this.onPresetSelected,
    this.enabled = true,
  });

  final StrokeWidthPreset? activePreset;
  final bool isMixed;
  final ValueChanged<StrokeWidthPreset> onPresetSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final presets = StrokeWidthPreset.values;

    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: swatchGap,
      children: [
        for (final preset in presets)
          StyleColorSwatch(
            color: SquiggleColors.base,
            isActive: !isMixed && activePreset == preset,
            enabled: enabled,
            onPressed: () => onPresetSelected(preset),
            overlay: CustomPaint(
              painter: _StrokeWidthPreviewPainter(
                barHeight: _previewBarHeight(preset),
                color: !isMixed && activePreset == preset
                    ? SquiggleColors.text
                    : SquiggleColors.subtext0,
              ),
            ),
          ),
      ],
    );
  }
}

class _StrokeWidthPreviewPainter extends CustomPainter {
  const _StrokeWidthPreviewPainter({
    required this.barHeight,
    required this.color,
  });

  final double barHeight;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final barWidth = size.width * 0.52;
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: barWidth,
        height: barHeight,
      ),
      Radius.circular(barHeight / 2),
    );
    canvas.drawRRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant _StrokeWidthPreviewPainter oldDelegate) {
    return oldDelegate.barHeight != barHeight || oldDelegate.color != color;
  }
}
