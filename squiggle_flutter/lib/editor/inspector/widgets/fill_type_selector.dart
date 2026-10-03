import 'package:flutter/material.dart';
import 'package:squiggle_flutter/editor/inspector/widgets/style_color_swatch.dart';
import 'package:squiggle_flutter/models/fill_type.dart';
import 'package:squiggle_flutter/painting/fill_painter.dart';
import 'package:squiggle_flutter/theme/squiggle_theme.dart';

class FillTypeSelector extends StatelessWidget {
  const FillTypeSelector({
    super.key,
    required this.activeType,
    required this.isMixed,
    required this.onTypeSelected,
    this.enabled = true,
  });

  final FillType? activeType;
  final bool isMixed;
  final ValueChanged<FillType> onTypeSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = context.squiggleTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: theme.spacing.swatchGap,
      children: [
        for (final type in FillType.values)
          Tooltip(
            message: switch (type) {
              FillType.solid => 'Solid',
              FillType.lines => 'Lines',
              FillType.crosshatch => 'Crosshatch',
            },
            child: StyleColorSwatch(
              color: theme.colors.base,
              isActive: !isMixed && activeType == type,
              enabled: enabled,
              onPressed: () => onTypeSelected(type),
              overlay: CustomPaint(
                painter: _FillTypePreviewPainter(
                  type: type,
                  color: !isMixed && activeType == type
                      ? theme.colors.text
                      : theme.colors.subtext0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FillTypePreviewPainter extends CustomPainter {
  const _FillTypePreviewPainter({required this.type, required this.color});

  final FillType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    paintFill(
      canvas,
      Path()..addRect(
        Rect.fromLTWH(
          size.width * 0.2,
          size.height * 0.2,
          size.width * 0.6,
          size.height * 0.6,
        ),
      ),
      Paint()..color = color,
      type,
      spacing: 5,
      lineWidth: 1,
    );
  }

  @override
  bool shouldRepaint(covariant _FillTypePreviewPainter oldDelegate) =>
      oldDelegate.type != type || oldDelegate.color != color;
}
